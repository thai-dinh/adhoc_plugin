import 'package:adhoclibrary/src/appframework/exceptions/bad_server_port.dart';
import 'package:uuid/uuid.dart';


class Config {
  static const int _MIN_PORT = 1023;
  static const int _MAX_PORT = 65535;

  int _serverPort;

  String label;
  bool connectionFlooding;
  int timeOut;

  Config({String label = '', bool connectionFlooding = false, int serverPort = 52000}) {
    this.label = (label == '') ? Uuid().v4() : label;
    this.connectionFlooding = connectionFlooding;
    this.serverPort = serverPort;
    this.timeOut = 5000;
  }

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

  int get serverPort => _serverPort;
}