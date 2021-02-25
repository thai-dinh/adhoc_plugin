import 'dart:async';
import 'dart:typed_data';

import 'package:adhoclibrary/src/datalink/ble/ble_adhoc_manager.dart';
import 'package:adhoclibrary/src/datalink/service/connect_status.dart';
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

  StreamController<ConnectStatus> _controller;
  StreamSubscription<dynamic> _conStreamSub;

  BleServer(bool verbose) : super(verbose, Service.STATE_NONE) {
    BleAdHocManager.setVerbose(verbose);
    this._controller = StreamController<ConnectStatus>();
  }

/*------------------------------Getters & Setters-----------------------------*/

  Stream<ConnectStatus> get connStatusStream async* {
    await for (ConnectStatus status in _controller.stream) {
      yield status;
    }
  }

  Stream<MessageAdHoc> get messageStream async* {
    await for (Map map in _chMessage.receiveBroadcastStream()) {
      MessageAdHoc message = 
        processMessage((map['message'] as List<dynamic>).cast<Uint8List>());

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

      if (verbose) log(ServiceServer.TAG, 'Server: message received');

      yield message;
    }
  }

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
            _controller.add(ConnectStatus(Service.CONNECTION_PERFORMED, address: mac));
            break;

          case Service.STATE_NONE:
            removeInactiveConnection(mac);
            _controller.add(ConnectStatus(Service.CONNECTION_CLOSED, address: mac));
            break;
        }
      },
    );

    state = Service.STATE_LISTENING;
  }

  void stopListening() {
    if (verbose) log(ServiceServer.TAG, 'Server: stopListening');

    if (_conStreamSub != null) {
      _conStreamSub.cancel();
      _conStreamSub = null;
    }

    BleAdHocManager.closeGattServer();

    state = Service.STATE_NONE;
  }

  Future<void> cancelConnection(String mac) async {
    if (verbose) log(ServiceServer.TAG, 'Server: cancelConnection() -> $mac');

    await BleAdHocManager.cancelConnection(mac);
  }

  Future<void> send(MessageAdHoc message, String mac) async {
    if (verbose) log(ServiceServer.TAG, 'Server: send() -> $mac');

    await BleAdHocManager.gattServerSendMessage(message, mac);
  }
}
