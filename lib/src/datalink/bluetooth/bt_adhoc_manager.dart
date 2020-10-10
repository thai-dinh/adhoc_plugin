import 'dart:async';
import 'dart:collection';

import 'package:AdHocLibrary/src/datalink/bluetooth/bt_adhoc_device.dart';
import 'package:AdHocLibrary/src/datalink/exceptions/bt_bad_duration.dart';

import 'package:flutter/services.dart';

class BluetoothAdHocManager {
  static const stream = const EventChannel('ad.hoc.library.dev/bluetooths.stream');
  static const platform = const MethodChannel('ad.hoc.library.dev/bluetooth');

  String _initialName;

  /// Constructor
  BluetoothAdHocManager() {
    getAdapterName().then((value) => _initialName = value);
  }

  Future<dynamic> _invokeMethod(String methodName, [dynamic arguments]) async {
    dynamic _value;

    try {
        _value = await platform.invokeMethod(methodName, arguments);
    } on PlatformException catch (error) {
      print(error.message);
    }

    return _value;
  }

  void enable() => _invokeMethod('enable');

  void disable() => _invokeMethod('disable');

  Future<String> getAdapterName() async  => await _invokeMethod('getName');

  Future<bool> updateDeviceName(String name) async 
    => await _invokeMethod('updateDeviceName', <String, dynamic> { 'name': name });

  void resetDeviceName() {
    if (_initialName != null)
      _invokeMethod('resetDeviceName', <String, dynamic> { 'name': _initialName });
  }

  Future<void> enableDiscovery(int duration) async {
    bool _isEnabled = await _invokeMethod('isEnabled');

    if (duration < 0 || duration > 3600) {
      String msg = 'Duration must be between [0; 3600] second(s).';
      throw new BluetoothBadDuration(msg);
    }

    if (_isEnabled)
      _invokeMethod('enableDiscovery', <String, dynamic> { 'duration': duration });
  }

  void discovery() {
    stream.receiveBroadcastStream().listen((event) { print(event); });

    _invokeMethod('startDiscovery');
  }

  Future<HashMap<String, BluetoothAdHocDevice>> getPairedDevices() async {
    HashMap<String, BluetoothAdHocDevice> _pairedDevices = 
      HashMap<String, BluetoothAdHocDevice>();
    List<dynamic> devices = await _invokeMethod('getPairedDevices');

    devices.forEach((element) { 
      BluetoothAdHocDevice device = BluetoothAdHocDevice.map(element);
      _pairedDevices[device.getMacAddress()] = device;
    });

    return _pairedDevices;
  }

  void unpairDevice(String macAddress)
    => _invokeMethod('unpairDevice', <String, dynamic> { 
      'address': macAddress,
    });
}