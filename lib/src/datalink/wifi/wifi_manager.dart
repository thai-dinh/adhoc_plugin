import 'package:flutter/services.dart';

class WifiManager {
  static const String _channelName = 'ad.hoc.lib/plugin.wifi.channel';
  static const MethodChannel _channel = const MethodChannel(_channelName);

  WifiManager();
}
