import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:adhoclibrary/src/datalink/ble/ble_adhoc_device.dart';
import 'package:adhoclibrary/src/datalink/ble/ble_adhoc_manager.dart';
import 'package:adhoclibrary/src/datalink/service/service_msg_listener.dart';
import 'package:adhoclibrary/src/datalink/service/service_server.dart';
import 'package:adhoclibrary/src/datalink/service/service.dart';
import 'package:adhoclibrary/src/datalink/stream/message_stream.dart';
import 'package:adhoclibrary/src/datalink/utils/msg_adhoc.dart';
import 'package:adhoclibrary/src/datalink/utils/utils.dart';
import 'package:flutter/services.dart';


class BleServer extends ServiceServer {
  static const String _chConnectName = 'ad.hoc.lib/ble.connection';
  static const EventChannel _chConnect = const EventChannel(_chConnectName);

  StreamSubscription<dynamic> _connectionStreamSub;
  StreamSubscription<dynamic> _messageStreamSub;

  BleServer(
    bool verbose, ServiceMessageListener serviceMessageListener
  ) : super(verbose, Service.STATE_NONE, serviceMessageListener) {
    BleAdHocManager.updateVerbose(verbose);
  }

/*-------------------------------Public methods-------------------------------*/

  void send(MessageAdHoc message, String address) {
    BleAdHocManager.serverSendMessage(message, address);
  }

  void listen([int unused]) {
    if (v) Utils.log(ServiceServer.TAG, 'Server: listening');

    BleAdHocManager.openGattServer();

    _connectionStreamSub = _chConnect.receiveBroadcastStream().listen((event) {
      if (event['state'] == Utils.BLE_STATE_CONNECTED) {
        BleAdHocDevice device = BleAdHocDevice.fromMap(event);
        connected.putIfAbsent(event['macAddress'], () => device);
        serviceMessageListener.onConnection(event['macAddress']);
      } else {
        if (connected.containsKey(event['macAddress'])) {
          connected.remove(event['macAddress']);
          serviceMessageListener.onConnectionClosed(event['macAddress']);
        }
      }
    });

    _messageStreamSub = MessageStream.listen((event) {
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

    if (_connectionStreamSub != null)
      _connectionStreamSub.cancel();
    if (_messageStreamSub != null)
      _messageStreamSub.cancel();

    BleAdHocManager.closeGattServer();
  }
}
