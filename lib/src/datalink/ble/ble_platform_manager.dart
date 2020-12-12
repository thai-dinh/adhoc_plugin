import 'dart:typed_data';

import 'package:flutter/services.dart';

class BlePlatformManager {
  static const String _channelName = 'ad.hoc.lib/plugin.ble.stream';
  static const EventChannel _channel = const EventChannel(_channelName);

  BlePlatformManager();

  Stream<Uint8List> messageStream(String remoteAddress) async* {
    List<Uint8List> values = List.empty(growable: true);

    _channel.receiveBroadcastStream().listen((event) {
      if (event['macAddress'] == remoteAddress)
        values.add(event['values']);
    });

    yield values.removeAt(0);
  }
}
