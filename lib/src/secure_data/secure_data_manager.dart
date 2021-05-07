import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:adhoc_plugin/src/appframework/config.dart';
import 'package:adhoc_plugin/src/datalink/exceptions/device_failure.dart';
import 'package:adhoc_plugin/src/datalink/service/adhoc_device.dart';
import 'package:adhoc_plugin/src/datalink/service/adhoc_event.dart';
import 'package:adhoc_plugin/src/datalink/service/discovery_event.dart';
import 'package:adhoc_plugin/src/network/aodv/aodv_manager.dart';
import 'package:adhoc_plugin/src/network/datalinkmanager/constants.dart';
import 'package:adhoc_plugin/src/network/datalinkmanager/datalink_manager.dart';
import 'package:adhoc_plugin/src/secure_data/certificate.dart';
import 'package:adhoc_plugin/src/secure_data/certificate_repository.dart';
import 'package:adhoc_plugin/src/secure_data/constants.dart';
import 'package:adhoc_plugin/src/secure_data/crypto_engine.dart';
import 'package:adhoc_plugin/src/secure_data/data.dart';
import 'package:pointycastle/pointycastle.dart';


class SecureDataManager {
  final bool _verbose;

  AodvManager _aodvManager;
  DataLinkManager _datalinkManager;
  CertificateRepository _repository;
  CryptoEngine _engine;
  StreamController<AdHocEvent> _eventCtrl;

  SecureDataManager(this._verbose, Config config) {
    this._aodvManager = AodvManager(_verbose, config);
    this._datalinkManager = _aodvManager.dataLinkManager;
    this._repository = CertificateRepository();
    this._engine = CryptoEngine();
    this._eventCtrl = StreamController<AdHocEvent>.broadcast();
    this._initialize();
  }

/*------------------------------Getters & Setters-----------------------------*/

  DataLinkManager get datalinkManager => _datalinkManager;

  List<AdHocDevice> get directNeighbors => _datalinkManager.directNeighbors;

  Stream<AdHocEvent> get eventStream => _eventCtrl.stream;

  Stream<DiscoveryEvent> get discoveryStream => _aodvManager.discoveryStream;

/*------------------------------Public methods--------------------------------*/

  void send(Object data, String destination, bool encrypted) {
    if (_datalinkManager.checkState() == 0)
      throw DeviceFailureException('No wifi and bluetooth connectivity');

    if (encrypted) {
      Certificate certificate = _repository.getCertificate(destination);
      Uint8List encryptedData = _engine.encrypt(Utf8Encoder().convert(data.toString()), certificate.key);
      _aodvManager.sendMessageTo(Data(ENCRYPTED_DATA, encryptedData).toJson(), destination);
    } else {
      _aodvManager.sendMessageTo(Data(UNENCRYPTED_DATA, data).toJson(), destination);
    }
  }

  Future<bool> broadcast(Object data, bool encrypted) async {
    if (_datalinkManager.checkState() == 0)
      throw DeviceFailureException('No wifi and bluetooth connectivity');

    if (encrypted) {
      for (final neighbor in _datalinkManager.directNeighbors)
        send(data, neighbor.label, true);
      return true;
    } else {
      return await _datalinkManager.broadcastObject(Data(UNENCRYPTED_DATA, data).toJson());
    }
  }

  Future<bool> broadcastExcept(Object data, String excluded, bool encrypted) async {
    if (_datalinkManager.checkState() == 0)
      throw DeviceFailureException('No wifi and bluetooth connectivity');

    if (encrypted) {
      for (final neighbor in _datalinkManager.directNeighbors)
        if (neighbor.label != excluded)
          send(data, neighbor.label, true);
      return true;
    } else {
      return await _datalinkManager.broadcastObjectExcept(Data(UNENCRYPTED_DATA, data).toJson(), excluded);
    }
  }

/*------------------------------Private methods-------------------------------*/

  void _initialize() {
    _aodvManager.eventStream.listen((event) {
      switch (event.type) {
        case CONNECTION_EVENT:
          _eventCtrl.add(event);

          AdHocDevice neighbor = event.payload as AdHocDevice;
          Map data = Data(
            CERT_XCHG_BEGIN, 
            [_engine.publicKey.modulus.toString(), _engine.publicKey.exponent.toString()]
          ).toJson();

          _aodvManager.sendMessageTo(data, neighbor.label);
          break;

        case DATA_RECEIVED:
          List payload = event.payload as List;
          AdHocDevice sender = payload[0] as AdHocDevice;
          _processData(sender, Data.fromJson(payload[1] as Map));
          break;

        default:
          _eventCtrl.add(event);
      }
    });
  }

  void _processData(AdHocDevice sender, Data pdu) {
    switch (pdu.type) {
      case CERT_XCHG_BEGIN:
        List _pdu = pdu.payload;
        _issueCertificate(sender, RSAPublicKey(BigInt.parse(_pdu.first), BigInt.parse(_pdu.last)));
        Map data = Data(
          CERT_XCHG_END,
          [ _engine.publicKey.modulus.toString(), _engine.publicKey.exponent.toString()]
        ).toJson();

        _aodvManager.sendMessageTo(data, sender.label);
        break;

      case CERT_XCHG_END:
        List _pdu = pdu.payload;
        _issueCertificate(sender, RSAPublicKey(BigInt.parse(_pdu.first), BigInt.parse(_pdu.last)));
        break;

      case ENCRYPTED_DATA:
        _eventCtrl.add(AdHocEvent(DATA_RECEIVED, [sender, _engine.decrypt(pdu.payload as Uint8List)]));
        break;

      case UNENCRYPTED_DATA:
        _eventCtrl.add(AdHocEvent(DATA_RECEIVED, [sender, pdu.payload]));
        break;
    }
  }

  void _issueCertificate(AdHocDevice neighbor, RSAPublicKey key) {
    Certificate certificate = Certificate(neighbor.label, _aodvManager.label, key);
    Uint8List signature = _engine.sign(Utf8Encoder().convert(certificate.toString()));
    certificate.signature = signature;
    _repository.addCertificate(certificate);
  }
}
