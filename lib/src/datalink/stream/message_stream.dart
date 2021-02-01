import 'dart:async';

import 'package:flutter/services.dart';


class MessageStream {
  static const String _channelName = 'ad.hoc.lib/ble.message';
  static const EventChannel _channel = const EventChannel(_channelName);

  static StreamSubscription<dynamic> listen(void Function(dynamic) onData) {
    return _channel.receiveBroadcastStream().asBroadcastStream().listen(onData);
  }
}
