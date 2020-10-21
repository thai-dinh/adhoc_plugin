import 'package:AdHocLibrary/datalink/sockets/isocket.dart';
import 'package:AdHocLibrary/datalink/utils/message_adhoc.dart';
import 'package:AdHocLibrary/datalink/utils/utils.dart';

import 'package:flutter/services.dart';

class AdHocBluetoothSocket implements ISocket {
  static const String _channelName = 'ad.hoc.lib.dev/bt.socket';
  static const MethodChannel _channel = const MethodChannel(_channelName);

  final bool _secure;
  final String _address;

  AdHocBluetoothSocket(this._address, this._secure) {
    Utils.invokeMethod(_channel, 'connect', <String, dynamic> { 
      'address' : this._address,
      'secure' : this._secure,
    });
  }

  String get remoteAddress => _address;

  void close() {
    Utils.invokeMethod(_channel, 'close', <String, dynamic> { 
      'address' : this._address,
    });
  }

  void listen(Function onData) async {
    final int value = await Utils.invokeMethod(_channel, 'listen', <String, dynamic> { 
      'address' : this._address,
    });

    onData(value);
  }

  void write(MessageAdHoc msg) {
    Utils.invokeMethod(_channel, 'write', <String, dynamic> { 
      'address' : this._address,
      'message' : null,
    });
  }
}