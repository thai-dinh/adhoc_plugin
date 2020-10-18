import 'dart:io';

import 'package:AdHocLibrary/datalink/sockets/iserver_socket.dart';

class AdHocWifiServerSocket implements IServerSocket {
  ServerSocket _serverSocket;

  AdHocWifiServerSocket(this._serverSocket);

  void close() => _serverSocket.close();

  void accept() => _serverSocket.listen((event) { });
}