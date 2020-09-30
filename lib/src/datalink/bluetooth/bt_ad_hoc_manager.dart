import 'dart:async';

import 'package:AdHocLibrary/src/datalink/exceptions/bt_bad_duration.dart';
import 'package:flutter/services.dart';

class BluetoothAdHocManager {
  static const platform = const MethodChannel('ad.hoc.library.dev/bluetooth');
  
  String _initialName;

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
    bool isEnabled = false;

    try {
      isEnabled = await platform.invokeMethod('isBtAdapterEnabled');
    } on PlatformException catch (error) {
      print(error.message);
    }

    if (duration < 0 || duration > 3600) {
      String msg = 'Duration must be between [0; 3600] second(s).';
      throw new BluetoothBadDuration(msg);
    }

    if (isEnabled) {
      try {
        final int code = await platform.invokeMethod('enableBtDiscovery', 
                                                     <String, dynamic> {
                                                       'duration': duration,
                                                     });
        if (code != 0) {
          // Something went wrong
        }
      } on PlatformException catch (error) {
        print(error.message);
      }
    } else {
      print("Enabling discovery failed!");
    }
  }

  // To check this method
  Future<bool> updateDeviceName(String name) async {
    bool result = false;

    try {
      result = await platform.invokeMethod('updateDeviceName', 
                                           <String, dynamic> {
                                             'name': name,
                                           });
    } on PlatformException catch (error) {
      print(error.message);
    }

    return result;
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
}