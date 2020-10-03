import 'dart:async';

import 'package:AdHocLibrary/src/datalink/exceptions/bt_bad_duration.dart';
import 'package:flutter/services.dart';

class BluetoothAdHocManager {
  static const platform = const MethodChannel('ad.hoc.library.dev/bluetooth');
  
  String _initialName;

  BluetoothAdHocManager() {
    getAdapterName().then((value) => _initialName = value);
  }

  Future<void> _invokeMethod(String methodName, [dynamic arguments]) async {
    try {
      if (arguments != null) {
        await platform.invokeMethod(methodName, arguments);
      } else {
        await platform.invokeMethod(methodName);
      }
    } on PlatformException catch (error) {
      print(error.message);
    }
  }

  void enable() {
    _invokeMethod('enable');
  }

  void disable() {
    _invokeMethod('disable');
  }

  Future<String> getAdapterName() async {
    String _name;

    try {
      _name = await platform.invokeMethod('getName');
    } on PlatformException catch (error) {
      print(error.message);
    }

    return _name;
  }

  Future<bool> updateDeviceName(String name) async {
    bool _result = false;

    try {
      _result = await platform.invokeMethod('updateDeviceName', 
        <String, dynamic> {
          'name': name,
        });
      print(_result);
    } on PlatformException catch (error) {
      print(error.message);
    }

    return _result;
  }

  void resetDeviceName() {
    if (_initialName != null) {
      _invokeMethod('resetDeviceName', <String, dynamic> {
        'name': _initialName,
      });
    }
  }

  Future<void> enableDiscovery(int duration) async {
    bool _isEnabled = false;

    try {
      _isEnabled = await platform.invokeMethod('isEnabled');
    } on PlatformException catch (error) {
      print(error.message);
    }

    if (duration < 0 || duration > 3600) {
      String msg = 'Duration must be between [0; 3600] second(s).';
      throw new BluetoothBadDuration(msg);
    }

    if (_isEnabled) {
      _invokeMethod('enableDiscovery', <String, dynamic> { 
        'duration': duration,
      });
    } else {
      print("Enabling discovery mode failed.");
    }
  }

  void discovery() {
    _cancelDiscovery();

    _invokeMethod('startDiscovery');
  }

  Future<void> _cancelDiscovery() async {
    bool _isDiscovering = false;

    try {
      _isDiscovering = await platform.invokeMethod('isDiscovering');
    } on PlatformException catch (error) {
      print(error.message);
    }

    if (_isDiscovering) {
      _invokeMethod('cancelDiscovery');
    }
  }
}