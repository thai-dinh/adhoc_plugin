import 'dart:collection';

import 'package:adhoclibrary/src/datalink/ble/ble_service_client.dart';
import 'package:adhoclibrary/src/datalink/ble/ble_adhoc_device.dart';
import 'package:adhoclibrary/src/datalink/ble/ble_util.dart';
import 'package:adhoclibrary/src/datalink/message/msg_adhoc.dart';

import 'package:flutter/services.dart';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BleServiceManager {
  static const String _channelName = 'ad.hoc.lib/ble.connection';
  static const EventChannel _channel = const EventChannel(_channelName);

  FlutterReactiveBle _bleClient;
  HashMap<String, BleServiceClient> _clients;
  HashMap<String, BleAdHocDevice> _discovered;

  BleServiceManager(this._bleClient) {
    this._clients = HashMap();

    _listenConnectionEvent();
  }

  void _listenConnectionEvent() {
    _channel.receiveBroadcastStream().listen((event) {
      if (event['state'] == STATE_CONNECTED) {
        BleAdHocDevice device = BleAdHocDevice.fromMap(event);
        BleServiceClient serviceClient = 
          BleServiceClient(_bleClient, device, 3, 5);

        serviceClient.listenMessageEvent();

        _clients.putIfAbsent(event['macAddress'], () => serviceClient);
      } else { // STATE_DISCONNECTED
        _clients.remove(event['macAddress']);
      }
    });
  }

  set discovered(HashMap<String, BleAdHocDevice> discovered)
    => _discovered = discovered;

  void connect() => _discovered.forEach((key, value) {
    BleServiceClient serviceClient = BleServiceClient(_bleClient, value, 3, 5);
    serviceClient.connect();
    _clients.putIfAbsent(key, () => serviceClient);
  });

  void sendMessage(MessageAdHoc msg) =>
    _clients.forEach((key, value) { value.sendMessage(msg); });
  
  void receiveMessage() => 
    _clients.forEach((key, value) { 
      print(value.receiveMessage().toString());
    });
}
