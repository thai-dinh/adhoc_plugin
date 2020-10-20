import 'dart:io';

import 'package:AdHocLibrary/datalink/sockets/isocket.dart';

class AdHocWifiSocket implements ISocket {
  final Socket _socket;

  AdHocWifiSocket(this._socket);

  String get remoteAddress => _socket.remoteAddress.address;

  void close() => _socket.close();

  void listen(Function onData) => _socket.listen(onData);

  void write(Object msg) => _socket.write(msg);
}