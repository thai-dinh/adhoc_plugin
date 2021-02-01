import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:adhoclibrary/src/datalink/ble/ble_adhoc_device.dart';
import 'package:adhoclibrary/src/datalink/ble/ble_adhoc_manager.dart';
import 'package:adhoclibrary/src/datalink/service/service_server.dart';
import 'package:adhoclibrary/src/datalink/service/service.dart';
import 'package:adhoclibrary/src/datalink/utils/msg_adhoc.dart';
import 'package:adhoclibrary/src/datalink/utils/utils.dart';
import 'package:flutter/services.dart';


class BleServer extends ServiceServer {
  static const String _chConnectName = 'ad.hoc.lib/ble.connection';
  static const String _chMessageName = 'ad.hoc.lib/ble.message';
  static const EventChannel _chConnect = const EventChannel(_chConnectName);
  static const EventChannel _chMessage = const EventChannel(_chMessageName);

  bool _verbose;
  HashMap<String, BleAdHocDevice> _connected;
  List<MessageAdHoc> _messages;
  StreamSubscription<dynamic> _connectionStreamSub;
  StreamSubscription<dynamic> _messageStreamSub;

  BleServer(this._verbose) : super(Service.STATE_NONE) {
    this._connected = HashMap<String, BleAdHocDevice>();
    this._messages = List.empty(growable: true);

    BleAdHocManager.updateVerbose(_verbose);
  }

/*------------------------------Getters & Setters-----------------------------*/

  HashMap<String, BleAdHocDevice> get activeConnections => _connected;

/*-------------------------------Public methods-------------------------------*/

  void listen() {
    if (_verbose) Utils.log(ServiceServer.TAG, 'Server: listening');

    BleAdHocManager.openGattServer();

    _connectionStreamSub= _chConnect.receiveBroadcastStream().listen((event) {
      if (event['state'] == Service.STATE_CONNECTED) {
        BleAdHocDevice device = BleAdHocDevice.fromMap(event);
        _connected.putIfAbsent(event['macAddress'], () => device);
      } else {
        if (_connected.containsKey(event['macAddress']))
          _connected.remove(event['macAddress']);
      }
    });

    _messageStreamSub = _chMessage.receiveBroadcastStream().listen((event) {
      List<Uint8List> rawMessage = 
          List<Uint8List>.from(event['values'].whereType<Uint8List>());
      Uint8List _unprocessedMessage = Uint8List.fromList(rawMessage.expand((x) {
        List<int> tmp = new List<int>.from(x); 
        tmp.removeAt(0);
        return tmp;
      }).toList());

      String stringMessage = Utf8Decoder().convert(_unprocessedMessage);
      MessageAdHoc message = MessageAdHoc.fromJson(json.decode(stringMessage));
      _messages.add(message);
    });
  }

  void stopListening() {
    if (_verbose) Utils.log(ServiceServer.TAG, 'Server: stop listening');

    if (_connectionStreamSub != null)
      _connectionStreamSub.cancel();
    if (_messageStreamSub != null)
      _messageStreamSub.cancel();

    BleAdHocManager.closeGattServer();
  }
}
