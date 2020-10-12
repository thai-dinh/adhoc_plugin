import 'dart:async';

import 'package:flutter/services.dart';

class WifiAdHocManager {
  static const platform = const MethodChannel('ad.hoc.library.dev/wifi');

  String _adapterName;

  WifiAdHocManager();

  String get adapterName => _adapterName;

  Future<dynamic> _invokeMethod(String methodName, [dynamic arguments]) async {
    dynamic _value;

    try {
        _value = await platform.invokeMethod(methodName, arguments);
    } on PlatformException catch (error) {
      print(error.message);
    }

    return _value;
  }

  static bool isWifiEnabled() { }

  void enable() => _invokeMethod('enable');

  void disable() => _invokeMethod('disable');

  bool updateDeviceName(String name) { }

  void resetDeviceName() { }
}