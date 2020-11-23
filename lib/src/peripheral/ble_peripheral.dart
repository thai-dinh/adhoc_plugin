import 'package:flutter/services.dart';

class Peripheral {
  static const String _channelName = 'ad.hoc.lib/blue.manager.channel';
  static const MethodChannel _channel = const MethodChannel(_channelName);

  Peripheral();

  void startAdvertise() => _channel.invokeMethod('startAdvertise');

  void stopAdvertise() => _channel.invokeMethod('stopAdvertise');
}