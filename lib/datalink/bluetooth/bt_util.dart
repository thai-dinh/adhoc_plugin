import 'dart:async';

import 'package:AdHocLibrary/datalink/utils/utils.dart';
import 'package:flutter/services.dart';
import 'package:get_mac/get_mac.dart';

class BluetoothUtil {
  static const channel 
    = const MethodChannel('ad.hoc.library.dev/bluetooth.channel');

  Future<String> getCurrentMac() async => await GetMac.macAddress;

  Future<String> getCurrentName() async
    => await Utils.invokeMethod(channel, 'getName');

  Future<bool> isEnabled() async 
    => await Utils.invokeMethod(channel, 'isEnabled');
}