import 'package:AdHocLibrary/datalink/utils/utils.dart';
import 'package:flutter/services.dart';

class BluetoothSocket {
  static const String _channelName = 'ad.hoc.lib.dev/bt.socket';
  static const MethodChannel _channel = const MethodChannel(_channelName);
 
  final String _address;

  BluetoothSocket(this._address) {
    Utils.invokeMethod(_channel, 'createSocket', <String, dynamic> { 
      'address': _address,
    });
  }

  void close() => Utils.invokeMethod(_channel, 'close');

  Object inputStream() {

  }

  void outputStream() {
    
  }
}