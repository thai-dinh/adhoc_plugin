import 'package:adhoclibrary/src/appframework/exceptions/bad_server_port.dart';

class Config {
  static const int _MIN_PORT = 1023;
  static const int _MAX_PORT = 65535;

  int _serverPort;

  String label;
  bool connectionFlooding;
  int timeOut;

  Config() {
    this.connectionFlooding = false;
    this.timeOut = 5000;
    this.serverPort = 52000;
  }

  Config.init(this.connectionFlooding, int serverPort) {
    this.serverPort = serverPort;
  }

  int get serverPort => _serverPort;

  set serverPort(int serverPort) {
    if (serverPort <= _MIN_PORT || serverPort >= _MAX_PORT) {
      throw BadServerPortException(
        'The server port must be in range [' + 
        (_MIN_PORT + 1).toString() + ' , ' + (_MAX_PORT - 1).toString() + ']'
      );
    } else {
      this._serverPort = serverPort;
    }
  }
}
