import 'constants.dart';
import 'exceptions/bad_server_port.dart';
import 'package:uuid/uuid.dart';


/// Class allowing to modify the library's behaviour via parameters.
class Config {
  late int _serverPort;

  late String label;
  late bool flood;
  late int timeOut;
  late int expiryTime;
  late int validityPeriod;
  late int validityCheck;

  /// Creates a [Config] object.
  /// 
  /// If [label] is given, it is used as the unique identifier of the device.
  /// Otherwise, a random UUID is generated.
  /// 
  /// If [flood] is set to true, then internal flooding mechanisms are activated,
  /// e.g., flood new connection events.
  /// 
  /// If [serverPort] is given, then it is used instead of the default one 
  /// (52000). The port number should be exclusively bewteen 1023 and 65535. 
  /// Otherwise, a [BadServerPortException] exception is thrown.
  /// 
  /// If [expiryTime] is given, then it is used instead of the default one 
  /// (10 seconds).
  /// 
  /// If [validityPeriod] is given, then it is used instead of the default one 
  /// (7200 seconds).
  /// 
  /// If [validityCheck] is given, then it is used instead of the default one 
  /// (7200 seconds).
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

/*-----------------------------fe-Getters & Setters-----------------------------*/

  /// Port value of the server socket (Wi-Fi Direct).
  int get serverPort => _serverPort;

  /// Port value of the server socket (Wi-Fi Direct).
  /// 
  /// Throws a [BadServerPortException] exception if the given server port value
  /// is invalid (1023 < [serverPort] < 65535).
  set serverPort(int serverPort) {
    if (serverPort <= MIN_PORT || serverPort >= MAX_PORT) {
      throw BadServerPortException(
        'The server port must be in range [${MIN_PORT + 1} , ${MAX_PORT - 1}]'
      );
    } else {
      _serverPort = serverPort;
    }
  }
}
