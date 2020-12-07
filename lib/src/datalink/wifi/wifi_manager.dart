import 'dart:collection';

import 'package:adhoclibrary/src/datalink/wifi/wifi_adhoc_device.dart';

import 'package:flutter/services.dart';

import 'package:flutter_p2p/flutter_p2p.dart';

class WifiManager {
  static const String _mChannelName = 'ad.hoc.lib/plugin.wifi.channel';
  static const String _eChannelName = 'ad.hoc.lib/plugin.wifi.stream';
  static const MethodChannel _mChanel = const MethodChannel(_mChannelName);
  static const EventChannel _stream = const EventChannel(_eChannelName);

  HashMap _mapDevices; 

  WifiManager() {
    _mapDevices = HashMap<String, WifiAdHocDevice>();
  }

  void startDiscovery() {
    _mapDevices.clear();

    _mChanel.invokeMethod('startDiscovery');

    _stream.receiveBroadcastStream().listen((event) {
      _mapDevices.putIfAbsent(
        event['deviceAddress'], 
        () => WifiAdHocDevice.map(event)
      );
    });
  }

  void stopDiscovery() => _mChanel.invokeMethod('stopDiscovery');

  void connect() => _mChanel.invokeMethod('connect', <String, dynamic> {
    'address': 'mac'
  });

  void cancelConnection() => _mChanel.invokeMethod('cancelConnection');

  Future<bool> _checkPermission() async {
    if (!await FlutterP2p.isLocationPermissionGranted()) {
      await FlutterP2p.requestLocationPermission();
      return false;
    }
    return true;
  }
}
