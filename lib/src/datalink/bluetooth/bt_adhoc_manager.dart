import 'dart:async';
import 'dart:collection';

import 'package:adhoclibrary/src/datalink/bluetooth/bt_adhoc_device.dart';
import 'package:adhoclibrary/src/datalink/exceptions/bad_duration_exception.dart';
import 'package:adhoclibrary/src/datalink/utils/utils.dart';

import 'package:flutter/services.dart';

class BluetoothAdHocManager {
  static const _channel = const MethodChannel('ad.hoc.lib/blue.manager.channel');
  static const _stream = const EventChannel('ad.hoc.lib/blue.manager.stream');

  String _initialName;

  /// Constructor
  BluetoothAdHocManager() {
    // getAdapterName().then((value) => _initialName = value);
    print("Herer");
  }

  void enable() => invokeMethod(_channel, 'enable');

  void disable() => invokeMethod(_channel, 'disable');

  Future<String> getAdapterName() async {
    return await invokeMethod(_channel, 'getName');
  }

  Future<bool> updateDeviceName(String name) async {
    return await invokeMethod(_channel, 'updateDeviceName', 
      <String, dynamic> {
        'name': name
      });
  }

  void resetDeviceName() {
    if (_initialName != null) {
      invokeMethod(_channel, 'resetDeviceName', <String, dynamic> {
        'name': _initialName
      });
    }
  }

  Future<void> enableDiscovery(int duration) async {
    bool _isEnabled = await invokeMethod(_channel, 'isEnabled');

    if (duration < 0 || duration > 3600) {
      String msg = 'Duration must be between [0; 3600] second(s).';
      throw new BadDurationException(msg);
    }

    if (_isEnabled) {
      invokeMethod(_channel, 'enableDiscovery', <String, dynamic> {
        'duration': duration
      });
    }
  }

  void discovery() {
    _stream.receiveBroadcastStream().listen((event) { print(event); });

    invokeMethod(_channel, 'startDiscovery');
  }

  Future<HashMap<String, BluetoothAdHocDevice>> getPairedDevices() async {
    HashMap<String, BluetoothAdHocDevice> _pairedDevices = 
      HashMap<String, BluetoothAdHocDevice>();
    List<dynamic> devices = await invokeMethod(_channel, 'getPairedDevices');

    devices.forEach((element) { 
      BluetoothAdHocDevice device = BluetoothAdHocDevice.map(element);
      _pairedDevices[device.macAddress] = device;
    });

    return _pairedDevices;
  }

  void unpairDevice(String macAddress) {
    invokeMethod(_channel, 'unpairDevice', <String, dynamic> { 
      'address': macAddress,
    });
  }
}