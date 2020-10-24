import 'package:AdHocLibrary/datalink/sockets/iserver_socket.dart';
import 'package:AdHocLibrary/datalink/utils/utils.dart';

import 'package:flutter/services.dart';

class AdHocBluetoothServerSocket implements IServerSocket {
  static const String _channelName = 'ad.hoc.lib.dev/bt.servers.socket';
  static const MethodChannel _channel = const MethodChannel(_channelName);

  AdHocBluetoothServerSocket(String uuidString, bool secure) {
    Utils.invokeMethod(_channel, 'create', <String, dynamic> { 
      'uuidString' : uuidString,
      'secure' : secure,
    });
  }

  void accept(Function onEvent) async {
    Utils.invokeMethod(_channel, 'accept').then(onEvent);
  }

  void close() => Utils.invokeMethod(_channel, 'close');
}