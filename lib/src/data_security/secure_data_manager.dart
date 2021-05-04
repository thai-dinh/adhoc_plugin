import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:adhoc_plugin/src/appframework/config.dart';
import 'package:adhoc_plugin/src/data_security/certificate.dart';
import 'package:adhoc_plugin/src/data_security/certificate_repository.dart';
import 'package:adhoc_plugin/src/data_security/constants.dart';
import 'package:adhoc_plugin/src/data_security/crypto_engine.dart';
import 'package:adhoc_plugin/src/data_security/data.dart';
import 'package:adhoc_plugin/src/datalink/service/adhoc_device.dart';
import 'package:adhoc_plugin/src/datalink/service/adhoc_event.dart';
import 'package:adhoc_plugin/src/datalink/service/discovery_event.dart';
import 'package:adhoc_plugin/src/network/aodv/aodv_manager.dart';
import 'package:adhoc_plugin/src/network/datalinkmanager/constants.dart';
import 'package:pointycastle/pointycastle.dart';


class SecureDataManager {
  final bool _verbose;

  AodvManager _aodvManager;
  CertificateRepository _repository;
  CryptoEngine _engine;
  StreamController<AdHocEvent> _controller;

  SecureDataManager(this._verbose, Config config) {
    this._aodvManager = AodvManager(_verbose, config);
    this._repository = CertificateRepository();
    this._engine = CryptoEngine();
    this._controller = StreamController<AdHocEvent>.broadcast();
    this._initialize();
  }

/*------------------------------Getters & Setters-----------------------------*/

  Stream<AdHocEvent> get eventStream => _controller.stream;

  Stream<DiscoveryEvent> get discoveryStream => _aodvManager.discoveryStream;

/*------------------------------Public methods--------------------------------*/

  void sendMessageTo(Object pdu, String label) {
    _aodvManager.sendMessageTo([false, pdu], label);
  }

  void sendEncryptedMessageTo(Object pdu, String label) {
    Certificate certificate = _repository.getCertificate(label);
    Uint8List encrypted = _engine.encrypt(Utf8Encoder().convert(pdu.toString()), certificate.key);
    _aodvManager.sendMessageTo(Data(ENCRYPTED_DATA, encrypted), label);
  }

/*------------------------------Private methods-------------------------------*/

  void _initialize() {
    _aodvManager.eventStream.listen((event) {
      switch (event.type) {
        case CONNECTION_EVENT:
          AdHocDevice neighbor = event.payload as AdHocDevice;
          _aodvManager.sendMessageTo(Data(CERT_XCHG_BEGIN, _engine.publicKey), neighbor.label);
          break;

        case DATA_RECEIVED:
          _processData(event.payload);
          break;

        default:
          _controller.add(event);
      }
    });
  }

  void _processData(Object data) {
    AdHocDevice neighbor = (data as List)[0] as AdHocDevice;
    Data pdu = (data as List)[1] as Data;
    switch (pdu.type) {
      case CERT_XCHG_BEGIN:
        _issueCertificate(neighbor, pdu.payload as RSAPublicKey);
        _aodvManager.sendMessageTo(Data(CERT_XCHG_END, _engine.publicKey), neighbor.label);
        break;

      case CERT_XCHG_END:
        _issueCertificate(neighbor, pdu.payload as RSAPublicKey);
        break;

      case ENCRYPTED_DATA:
        _controller.add(AdHocEvent(DATA_RECEIVED, _engine.decrypt(pdu.payload as Uint8List)));
        break;

      case UNENCRYPTED_DATA:
        _controller.add(AdHocEvent(DATA_RECEIVED, pdu.payload));
        break;
    }
  }

  void _issueCertificate(AdHocDevice neighbor, RSAPublicKey key) {
    Certificate certificate = Certificate(neighbor.label, _aodvManager.ownLabel, key);
    Uint8List signature = _engine.sign(Utf8Encoder().convert(certificate.toString()));
    certificate.signature = signature;
    _repository.addCertificate(certificate);
  }
}
