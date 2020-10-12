import 'dart:async';

import 'package:flutter/services.dart';
import 'package:get_mac/get_mac.dart';

class BluetoothUtil {
  static const platform = const MethodChannel('ad.hoc.library.dev/bluetooth.channel');

  Future<String> getCurrentMac() async => await GetMac.macAddress;

  Future<String> getCurrentName() async {
    String _name;

    try {
      _name = await platform.invokeMethod('getName');
    } on PlatformException catch (error) {
      print(error.message);
    }

    return _name;
  }

  Future<bool> isEnabled() async {
    bool _isEnabled;

    try {
      _isEnabled = await platform.invokeMethod('isEnabled');
    } on PlatformException catch (error) {
      print(error.message);
    }

    return _isEnabled;
  }
}