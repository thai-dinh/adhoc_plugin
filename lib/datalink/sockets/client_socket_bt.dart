import 'package:AdHocLibrary/datalink/sockets/isocket.dart';
import 'package:AdHocLibrary/datalink/utils/message_adhoc.dart';
import 'package:AdHocLibrary/datalink/utils/utils.dart';

import 'package:flutter/services.dart';

class AdHocBluetoothSocket implements ISocket {
  static const String _channelName = 'ad.hoc.lib.dev/bt.clients.socket';
  static const MethodChannel _channel = const MethodChannel(_channelName);

  final String _address;

  AdHocBluetoothSocket(this._address);

  String get remoteAddress => _address;

  Future<bool> connect(bool secure, String uuidString) async {
    return Utils.invokeMethod(_channel, 'connect', <String, dynamic> { 
      'address' : this._address,
      'secure' : secure,
      'uuidString' : uuidString,
    });
  }

  Future<bool> isConnected() async {
    return Utils.invokeMethod(_channel, 'isConnected', <String, dynamic> { 
      'address' : this._address,
    });
  }

  void close() {
    Utils.invokeMethod(_channel, 'close', <String, dynamic> { 
      'address' : this._address,
    });
  }

  void listen(Function onData) async {
    Utils.invokeMethod(_channel, 'listen', <String, dynamic> { 
      'address' : this._address,
    }).then((result) => onData(result));
  }

  void write(MessageAdHoc messageAdHoc) {
    Utils.invokeMethod(_channel, 'write', <String, dynamic> { 
      'address' : this._address,
      'message' : messageAdHoc,
    });
  }
}