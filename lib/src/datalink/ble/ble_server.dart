import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:adhoclibrary/src/datalink/ble/ble_adhoc_manager.dart';
import 'package:adhoclibrary/src/datalink/service/service_msg_listener.dart';
import 'package:adhoclibrary/src/datalink/service/service_server.dart';
import 'package:adhoclibrary/src/datalink/service/service.dart';
import 'package:adhoclibrary/src/datalink/utils/msg_adhoc.dart';
import 'package:adhoclibrary/src/datalink/utils/utils.dart';
import 'package:flutter/services.dart';


class BleServer extends ServiceServer {
  static const String _chConnectName = 'ad.hoc.lib/ble.connection';
  static const String _chMsgName = 'ad.hoc.lib/ble.message';
  static const EventChannel _chConnect = const EventChannel(_chConnectName);
  static const EventChannel _chMessage = const EventChannel(_chMsgName);

  StreamSubscription<dynamic> _connectStreamSub;
  StreamSubscription<dynamic> _msgStreamSub;

  BleServer(
    bool verbose, ServiceMessageListener serviceMessageListener
  ) : super(verbose, Service.STATE_NONE, serviceMessageListener) {
    BleAdHocManager.setVerbose(verbose);
  }

/*-------------------------------Public methods-------------------------------*/

  void send(MessageAdHoc message, String address) {
    BleAdHocManager.serverSendMessage(message, address);
  }

  void listen([int unused]) {
    if (v) Utils.log(ServiceServer.TAG, 'Server: listening');

    BleAdHocManager.openGattServer();

    _connectStreamSub = _chConnect.receiveBroadcastStream().listen((event) {
      String macAddress = event['macAddress'];
      if (event['state'] == Utils.BLE_STATE_CONNECTED) {
        addActiveConnection(macAddress);
        serviceMessageListener.onConnection(macAddress);
      } else {
        if (activeConnections.contains(macAddress)) {
          removeInactiveConnection(macAddress);
          serviceMessageListener.onConnectionClosed(macAddress);
        }
      }
    });

    _msgStreamSub = _chMessage.receiveBroadcastStream().listen((event) {
      List<Uint8List> rawMessage = 
          List<Uint8List>.from(event['values'].whereType<Uint8List>());
      Uint8List _unprocessedMessage = Uint8List.fromList(rawMessage.expand((x) {
        List<int> tmp = new List<int>.from(x);
        tmp.removeAt(0);
        return tmp;
      }).toList());

      String stringMessage = Utf8Decoder().convert(_unprocessedMessage);
      MessageAdHoc message = MessageAdHoc.fromJson(json.decode(stringMessage));
      serviceMessageListener.onMessageReceived(message);
    });
  }

  void stopListening() {
    if (v) Utils.log(ServiceServer.TAG, 'Server: stop listening');

    if (_connectStreamSub != null)
      _connectStreamSub.cancel();
    if (_msgStreamSub != null)
      _msgStreamSub.cancel();

    BleAdHocManager.closeGattServer();
  }
}
