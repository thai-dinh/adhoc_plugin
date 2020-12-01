import 'package:flutter/services.dart';

class WifiManager {
  static const String _channelName = 'ad.hoc.lib/plugin.wifi.channel';
  static const MethodChannel _channel = const MethodChannel(_channelName);

  WifiManager();

  void startDiscovery() => _channel.invokeMethod('startDiscovery');

  void stopDiscovery() => _channel.invokeMethod('stopDiscovery');

  void connect() => _channel.invokeMethod('connect', <String, dynamic> {
    'address': 'mac'
  });
}
