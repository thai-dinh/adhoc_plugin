import 'package:flutter/services.dart';

class BlePlatformManager {
  static const String _channelName = 'ad.hoc.lib/plugin.ble.stream';
  static const EventChannel _channel = const EventChannel(_channelName);

  BlePlatformManager();

  Stream<dynamic> listen() => _channel.receiveBroadcastStream();
}