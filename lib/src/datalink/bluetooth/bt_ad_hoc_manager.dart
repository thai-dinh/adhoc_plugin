import 'dart:async';

import 'package:AdHocLibrary/src/datalink/exceptions/bt_bad_duration.dart';
import 'package:AdHocLibrary/src/datalink/service/discovery_listener.dart';
import 'package:flutter/services.dart';

class BluetoothAdHocManager {
  static const platform = const MethodChannel('ad.hoc.library.dev/bluetooth');
  
  String _initialName;
  DiscoveryListener _discoveryListener;

  BluetoothAdHocManager() {
    initialisation();
  }

  Future<void> initialisation() async {
    try {
      _initialName = await platform.invokeMethod('getName');
    } on PlatformException catch (error) {
      print(error.message);
    }
  }

  Future<void> enable() async {
    try {
      await platform.invokeMethod('enableBtAdapter');
    } on PlatformException catch (error) {
      print(error.message);
    }
  }

  Future<void> disable() async {
    try {
      await platform.invokeMethod('disableBtAdapter');
    } on PlatformException catch (error) {
      print(error.message);
    }
  }

  Future<void> enableDiscovery(int duration) async {
    bool _isEnabled = false;

    try {
      _isEnabled = await platform.invokeMethod('isBtAdapterEnabled');
    } on PlatformException catch (error) {
      print(error.message);
    }

    if (duration < 0 || duration > 3600) {
      String msg = 'Duration must be between [0; 3600] second(s).';
      throw new BluetoothBadDuration(msg);
    }

    if (_isEnabled) {
      try {
        await platform.invokeMethod('enableBtDiscovery', <String, dynamic> {
          'duration': duration,
        });
      } on PlatformException catch (error) {
        print(error.message);
      }
    } else {
      print("Enabling discovery mode failed.");
    }
  }

  // To check this method
  Future<bool> updateDeviceName(String name) async {
    bool _result = false;

    try {
      _result = await platform.invokeMethod('updateDeviceName', 
        <String, dynamic> {
          'name': name,
        });
    } on PlatformException catch (error) {
      print(error.message);
    }

    return _result;
  }

  // To check this method when [updateDeviceName] is updated
  Future<void> resetDeviceName() async {
    if (_initialName != null) {
      try {
        await platform.invokeMethod('resetDeviceName', <String, dynamic> {
          'name': _initialName,
        });
      } on PlatformException catch (error) {
        print(error.message);
      }
    }
  }

  Future<void> _cancelDiscovery() async {
    bool _isDiscovering = false;
    try {
      _isDiscovering = await platform.invokeMethod('isDiscovering');
    } on PlatformException catch (error) {
      print(error.message);
    }

    if (_isDiscovering) {
      try {
        platform.invokeMethod('cancelDiscovery');
      } on PlatformException catch (error) {
        print(error.message);
      }
    }

    // %TODO: unregisterDiscovery ?
  }

  void discovery(DiscoveryListener discoveryListener) {
    // Check if the device is already "discovering". If it is, then cancel it.
    _cancelDiscovery();

    // Update Listener
    this._discoveryListener = discoveryListener;

    // %TODO: finish
  }
}