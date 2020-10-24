import 'dart:async';

import 'package:AdHocLibrary/datalink/utils/utils.dart';
import 'package:flutter/services.dart';
import 'package:get_mac/get_mac.dart';

class BluetoothUtil {
  static const channel 
    = const MethodChannel('ad.hoc.library.dev/bluetooth.channel');
  static const String UUID = "e0917680-d427-11e4-8830-";

  Future<String> getCurrentMac() async => await GetMac.macAddress;

  Future<String> getCurrentName() async
    => await Utils.invokeMethod(channel, 'getName');

  Future<bool> isEnabled() async 
    => await Utils.invokeMethod(channel, 'isEnabled');
}