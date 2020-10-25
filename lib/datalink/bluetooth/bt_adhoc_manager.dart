import 'dart:async';
import 'dart:collection';

import 'package:AdHocLibrary/datalink/bluetooth/bt_adhoc_device.dart';
import 'package:AdHocLibrary/datalink/exceptions/bad_duration_exception.dart';
import 'package:AdHocLibrary/datalink/utils/utils.dart';

import 'package:flutter/services.dart';

class BluetoothAdHocManager {
  static const channel = const MethodChannel('ad.hoc.lib.dev/bt.channel');
  static const stream = const EventChannel('ad.hoc.lib.dev/bt.stream');

  String _initialName;

  /// Constructor
  BluetoothAdHocManager() {
    getAdapterName().then((value) => _initialName = value);
  }

  void enable() => Utils.invokeMethod(channel, 'enable');

  void disable() => Utils.invokeMethod(channel, 'disable');

  Future<String> getAdapterName() async {
    return await Utils.invokeMethod(channel, 'getName');
  }

  Future<bool> updateDeviceName(String name) async {
    return await Utils.invokeMethod(channel, 'updateDeviceName', 
      <String, dynamic> {
        'name': name
      });
  }

  void resetDeviceName() {
    if (_initialName != null)
      Utils.invokeMethod(channel, 'resetDeviceName', <String, dynamic> {
        'name': _initialName
      });
  }

  Future<void> enableDiscovery(int duration) async {
    bool _isEnabled = await Utils.invokeMethod(channel, 'isEnabled');

    if (duration < 0 || duration > 3600) {
      String msg = 'Duration must be between [0; 3600] second(s).';
      throw new BadDurationException(msg);
    }

    if (_isEnabled)
      Utils.invokeMethod(channel, 'enableDiscovery', <String, dynamic> {
        'duration': duration
      });
  }

  void discovery() {
    stream.receiveBroadcastStream().listen((event) { print(event); });

    Utils.invokeMethod(channel, 'startDiscovery');
  }

  Future<HashMap<String, BluetoothAdHocDevice>> getPairedDevices() async {
    HashMap<String, BluetoothAdHocDevice> _pairedDevices = 
      HashMap<String, BluetoothAdHocDevice>();
    List<dynamic> devices = 
      await Utils.invokeMethod(channel, 'getPairedDevices');

    devices.forEach((element) { 
      BluetoothAdHocDevice device = BluetoothAdHocDevice.map(element);
      _pairedDevices[device.macAddress] = device;
    });

    return _pairedDevices;
  }

  void unpairDevice(String macAddress) {
    Utils.invokeMethod(channel, 'unpairDevice', <String, dynamic> { 
      'address': macAddress,
    });
  }
}