import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:adhoclibrary/src/datalink/ble/ble_adhoc_manager.dart';
import 'package:adhoclibrary/src/datalink/service/connection_event.dart';
import 'package:adhoclibrary/src/datalink/service/service_server.dart';
import 'package:adhoclibrary/src/datalink/service/service.dart';
import 'package:adhoclibrary/src/datalink/utils/msg_adhoc.dart';
import 'package:adhoclibrary/src/datalink/utils/msg_header.dart';
import 'package:adhoclibrary/src/datalink/utils/utils.dart';
import 'package:flutter/services.dart';


class BleServer extends ServiceServer {
  static const String _chConnectName = 'ad.hoc.lib/ble.connection';
  static const String _chMessageName = 'ad.hoc.lib/ble.message';
  static const EventChannel _chConnect = const EventChannel(_chConnectName);
  static const EventChannel _chMessage = const EventChannel(_chMessageName);

  StreamController<ConnectionEvent> _controller;
  StreamController<MessageAdHoc> _msgCtrl;
  StreamSubscription<dynamic> _conStreamSub;
  StreamSubscription<dynamic> _msgSub;

  BleServer(bool verbose) : super(verbose, Service.STATE_NONE) {
    BleAdHocManager.setVerbose(verbose);
    this._controller = StreamController<ConnectionEvent>();
    this._msgCtrl = StreamController<MessageAdHoc>();
  }

/*------------------------------Getters & Setters-----------------------------*/

  Stream<ConnectionEvent> get connStatusStream => _controller.stream;

  Stream<MessageAdHoc> get messageStream => _msgCtrl.stream;

/*-------------------------------Public methods-------------------------------*/

  void start() {
    if (verbose) log(ServiceServer.TAG, 'Server: start()');

    BleAdHocManager.openGattServer();

    _conStreamSub = _chConnect.receiveBroadcastStream()
      .listen((map) {
        String mac = map['macAddress'] as String;
        switch (map['state']) {
          case Service.STATE_CONNECTED:
            addActiveConnection(mac);
            _controller.add(ConnectionEvent(Service.CONNECTION_PERFORMED, address: mac));
            break;

          case Service.STATE_NONE:
            removeInactiveConnection(mac);
            _controller.add(ConnectionEvent(Service.CONNECTION_CLOSED, address: mac));
            break;
        }
      }, onDone: () => _conStreamSub = null,
    );

    _msgSub = _chMessage.receiveBroadcastStream().listen((map) {
      if (verbose) log(ServiceServer.TAG, 'Server: message received');

      Uint8List messageAsListByte = 
        Uint8List.fromList((map['message'] as List<dynamic>).cast<Uint8List>().expand((x) => List<int>.from(x)..removeAt(0)..removeAt(0)).toList());
      String strMessage = Utf8Decoder().convert(messageAsListByte);
      MessageAdHoc message = MessageAdHoc.fromJson(json.decode(strMessage));

      if (message.header.mac.compareTo('') == 0) {
        message.header = Header(
          messageType: message.header.messageType,
          label: message.header.label,
          name: message.header.name,
          address: message.header.address,
          mac: map['macAddress'],
          deviceType: message.header.deviceType
        );
      }

      _msgCtrl.add(message);
    }, onDone: () => _msgSub = null);

    state = Service.STATE_LISTENING;
  }

  void stopListening() {
    if (verbose) log(ServiceServer.TAG, 'Server: stopListening');

    if (_conStreamSub != null)
      _conStreamSub.cancel();
    if (_msgSub != null)
      _msgSub.cancel();

    BleAdHocManager.closeGattServer();

    state = Service.STATE_NONE;
  }

  Future<void> cancelConnection(String mac) async {
    if (verbose) log(ServiceServer.TAG, 'Server: cancelConnection() -> $mac');

    await BleAdHocManager.cancelConnection(mac);
  }

  Future<void> send(MessageAdHoc message, String mac) async {
    if (verbose) log(ServiceServer.TAG, 'Server: send() -> $mac');

    print(await BleAdHocManager.gattServerSendMessage(message, mac));
  }
}
