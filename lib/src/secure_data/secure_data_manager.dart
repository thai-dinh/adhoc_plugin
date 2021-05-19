import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:adhoc_plugin/src/appframework/config.dart';
import 'package:adhoc_plugin/src/datalink/service/adhoc_device.dart';
import 'package:adhoc_plugin/src/datalink/service/adhoc_event.dart';
import 'package:adhoc_plugin/src/network/aodv/aodv_manager.dart';
import 'package:adhoc_plugin/src/network/datalinkmanager/constants.dart';
import 'package:adhoc_plugin/src/network/datalinkmanager/datalink_manager.dart';
import 'package:adhoc_plugin/src/secure_data/certificate.dart';
import 'package:adhoc_plugin/src/secure_data/certificate_repository.dart';
import 'package:adhoc_plugin/src/secure_data/constants.dart';
import 'package:adhoc_plugin/src/secure_data/crypto_engine.dart';
import 'package:adhoc_plugin/src/secure_data/secure_data.dart';
import 'package:adhoc_plugin/src/secure_data/secure_group_controller.dart';
import 'package:pointycastle/pointycastle.dart';


class SecureDataManager {
  final bool _verbose;

  late AodvManager _aodvManager;
  late DataLinkManager _datalinkManager;
  late CryptoEngine _engine;
  late CertificateRepository _repository;
  late SecureGroupController _groupController;
  late StreamController<AdHocEvent> _controller;

  SecureDataManager(this._verbose, Config config) {
    this._aodvManager = AodvManager(_verbose, config);
    this._datalinkManager = _aodvManager.dataLinkManager;
    this._repository = CertificateRepository(config);
    this._engine = CryptoEngine();
    this._groupController = SecureGroupController(
      _aodvManager, _datalinkManager, _aodvManager.eventStream, config
    );
    this._controller = StreamController<AdHocEvent>.broadcast();
    this._initialize();
  }

/*------------------------------Getters & Setters-----------------------------*/

  SecureGroupController? get groupController => _groupController;

  DataLinkManager? get datalinkManager => _datalinkManager;

  List<AdHocDevice> get directNeighbors => _datalinkManager.directNeighbors;

  Stream<AdHocEvent> get eventStream => _controller.stream;

/*------------------------------Public methods--------------------------------*/

  void send(Object data, String? destination, bool encrypted) async {
    if (encrypted) {
      Certificate certificate = _repository.getCertificate(destination)!;
      Uint8List encryptedData = await _engine.encrypt(Utf8Encoder().convert(JsonCodec().encode(data)), certificate.key);
      _aodvManager.sendMessageTo(destination!, SecureData(ENCRYPTED_DATA, encryptedData).toJson());
    } else {
      _aodvManager.sendMessageTo(destination!, SecureData(UNENCRYPTED_DATA, data).toJson());
    }
  }

  Future<bool> broadcast(Object data, bool encrypted) async {
    if (encrypted) {
      for (final neighbor in _datalinkManager.directNeighbors)
        send(data, neighbor.label, true);
      return true;
    } else {
      return await _datalinkManager.broadcastObject(SecureData(UNENCRYPTED_DATA, data).toJson());
    }
  }

  Future<bool> broadcastExcept(Object data, String? excluded, bool encrypted) async {
    if (encrypted) {
      for (final neighbor in _datalinkManager.directNeighbors)
        if (neighbor.label != excluded)
          send(data, neighbor.label, true);
      return true;
    } else {
      return await _datalinkManager.broadcastObjectExcept(SecureData(UNENCRYPTED_DATA, data).toJson(), excluded);
    }
  }

/*------------------------------Private methods-------------------------------*/

  void _initialize() {
    _aodvManager.eventStream.listen((event) {
      switch (event.type) {
        case CONNECTION_EVENT:
          _controller.add(event);

          AdHocDevice neighbor = event.payload as AdHocDevice;
          Map data = SecureData(
            CERT_XCHG_BEGIN, 
            [_engine.publicKey!.modulus.toString(), _engine.publicKey!.exponent.toString()]
          ).toJson();

          _aodvManager.sendMessageTo(neighbor.label!, data);
          break;

        case DATA_RECEIVED:
          List payload = event.payload as List;
          AdHocDevice sender = payload[0] as AdHocDevice;
          _processData(sender, SecureData.fromJson((payload[1] as Map) as Map<String, dynamic>));
          break;

        default:
          _controller.add(event);
      }
    });
  }

  void _processData(AdHocDevice sender, SecureData pdu) async {
    switch (pdu.type) {
      case CERT_XCHG_BEGIN:
        List _pdu = pdu.payload as List<dynamic>;
        _issueCertificate(sender, RSAPublicKey(BigInt.parse(_pdu.first), BigInt.parse(_pdu.last)));
        Map data = SecureData(
          CERT_XCHG_END,
          [ _engine.publicKey!.modulus.toString(), _engine.publicKey!.exponent.toString()]
        ).toJson();

        _aodvManager.sendMessageTo(sender.label!, data);
        break;

      case CERT_XCHG_END:
        List _pdu = pdu.payload as List<dynamic>;
        _issueCertificate(sender, RSAPublicKey(BigInt.parse(_pdu.first), BigInt.parse(_pdu.last)));
        break;

      case ENCRYPTED_DATA:
        List<int> received = (pdu.payload as List<dynamic>).cast<int>();
        Uint8List data = await _engine.decrypt(Uint8List.fromList(received));
        _controller.add(AdHocEvent(DATA_RECEIVED, [sender, JsonCodec().decode(Utf8Decoder().convert(data))]));
        break;

      case UNENCRYPTED_DATA:
        _controller.add(AdHocEvent(DATA_RECEIVED, [sender, pdu.payload]));
        break;

      default:
    }
  }

  void _issueCertificate(AdHocDevice neighbor, RSAPublicKey key) {
    Certificate certificate = Certificate(neighbor.label, _aodvManager.label, key);
    Uint8List signature = _engine.sign(Utf8Encoder().convert(certificate.toString()));
    certificate.signature = signature;
    _repository.addCertificate(certificate);
  }
}
