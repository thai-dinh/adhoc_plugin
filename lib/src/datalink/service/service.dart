import 'package:AdHocLibrary/src/datalink/service/service_message_listener.dart';

abstract class Service {
  // Constant for type
  static const int WIFI = 0;
  static const int BLUETOOTH = 1;

  // Constants that indicate the current connection state
  static const int STATE_NONE = 0;            // no connection
  static const int STATE_LISTENING = 1;       // listening for incoming connections
  static const int STATE_CONNECTING = 2;      // initiating an outgoing connection
  static const int STATE_CONNECTED = 3;       // connected to a remote device

  // Constants for message handling
  static const int MESSAGE_READ = 5;          // message received

  // Constants for connection
  static const int CONNECTION_ABORTED = 6;    // connection aborted
  static const int CONNECTION_PERFORMED = 7;  // connection performed
  static const int CONNECTION_FAILED = 8;     // connection failed

  static const int LOG_EXCEPTION = 9;         // log exception
  static const int MESSAGE_EXCEPTION = 10;    // catch message exception
  static const int NETWORK_UNREACHABLE = 11;

  bool _json;
  bool _verbose;
  int _state;

  ServiceMessageListener _serviceMessageListener;

  Service() {
    this._json = false;
    this._verbose = false;
    this._state = 0;
    this._serviceMessageListener = null;
  }

  Service.init(this._verbose, this._json, this._serviceMessageListener) {
    this._state = 0;
  }

  set state(int state) => this._state = state;

  int get state => _state;
}