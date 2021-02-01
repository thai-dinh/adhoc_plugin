import 'package:flutter/services.dart';


class BleUtils {
  static const String _channelName = 'ad.hoc.lib/plugin.ble.channel';
  static const MethodChannel _channel = const MethodChannel(_channelName);

  static const ADHOC_SERVICE_UUID = '00000001-0000-1000-8000-00805f9b34fb';
  static const ADHOC_CHARACTERISTIC_UUID = '00000002-0000-1000-8000-00805f9b34fb';

  static const MIN_MTU = 20;
  static const MAX_MTU = 512;

  static const MESSAGE_END = 0;
  static const MESSAGE_BEGIN = 1;

  static const UINT8_SIZE = 256;

  static const STATE_DISCONNECTED = 0;
  static const STATE_CONNECTED = 1;

  static Future<String> getCurrentName() async {
    return await _channel.invokeMethod('getCurrentName');
  }

  static Future<bool> isEnabled() async {
    return await _channel.invokeMethod('isEnabled');
  }
}
