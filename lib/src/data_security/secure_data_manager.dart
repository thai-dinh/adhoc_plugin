import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:adhoc_plugin/src/appframework/config.dart';
import 'package:adhoc_plugin/src/data_security/certificate.dart';
import 'package:adhoc_plugin/src/data_security/certificate_repository.dart';
import 'package:adhoc_plugin/src/data_security/constants.dart';
import 'package:adhoc_plugin/src/data_security/crypto_engine.dart';
import 'package:adhoc_plugin/src/datalink/service/adhoc_device.dart';
import 'package:adhoc_plugin/src/datalink/service/adhoc_event.dart';
import 'package:adhoc_plugin/src/datalink/service/discovery_event.dart';
import 'package:adhoc_plugin/src/network/aodv/aodv_manager.dart';
import 'package:adhoc_plugin/src/network/datalinkmanager/constants.dart';

class SecureDataManager {
  final bool _verbose;

  AodvManager _aodvManager;
  Base64Codec _codec;
  CertificateRepository _repository;
  CryptoEngine _engine;
  StreamController<AdHocEvent> _controller;

  SecureDataManager(this._verbose, Config config) {
    this._aodvManager = AodvManager(_verbose, config);
    this._codec = Base64Codec();
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
    Uint8List encrypted = 
      _engine.encrypt(_codec.decode(pdu.toString()), certificate.key);
    _aodvManager.sendMessageTo([true, encrypted], label);
  }

/*------------------------------Private methods-------------------------------*/

  void _initialize() {
    _aodvManager.eventStream.listen((event) {
      switch (event.type) {
        case CONNECTION_EVENT:
          AdHocDevice neighbor = event.payload as AdHocDevice;
          _aodvManager.sendMessageTo([CERTIFICATE_EXCHANGE, _engine.publicKey], neighbor.label);
          break;

        case DATA_RECEIVED:
          List<dynamic> payload = event.payload as List<dynamic>;
          AdHocDevice sender = payload[0];
          bool state = (payload[1] as List<dynamic>)[0];
          Object pdu = (payload[1] as List<dynamic>)[1];
          if (state)
            pdu = _engine.decrypt(pdu);

          _controller.add(AdHocEvent(DATA_RECEIVED, [sender, pdu]));
          break;

        default:
          _controller.add(event);
      }
    });
  }
}
