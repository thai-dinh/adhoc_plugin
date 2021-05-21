import 'package:adhoc_plugin/src/appframework/constants.dart';
import 'package:adhoc_plugin/src/appframework/exceptions/bad_server_port.dart';
import 'package:uuid/uuid.dart';


class Config {
  late int _serverPort;

  late String label;
  late bool flood;
  late int timeOut;
  late int expiryTime;
  late int validityPeriod;
  late int validityCheck;

  Config({
    String label = '', bool flood = false, int serverPort = 52000,
    int expiryTime = 10, int validityPeriod = 7200, int validityCheck = 7200
  }) {
    this.label = (label == '') ? Uuid().v4() : label;
    this.flood = flood;
    this.serverPort = serverPort;
    this.timeOut = 5000;
    this.expiryTime = expiryTime;
    this.validityPeriod = validityPeriod;
    this.validityCheck = validityCheck;
  }

/*------------------------------Getters & Setters-----------------------------*/

  set serverPort(int serverPort) {
    if (serverPort <= MIN_PORT || serverPort >= MAX_PORT) {
      throw BadServerPortException(
        'The server port must be in range [${MIN_PORT + 1} , ${MAX_PORT - 1}]'
      );
    } else {
      this._serverPort = serverPort;
    }
  }

  int get serverPort => _serverPort;
}
