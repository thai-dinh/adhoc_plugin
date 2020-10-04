import 'package:AdHocLibrary/src/datalink/service/service_message_listener.dart';

class Service {
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

  int state;
  bool verbose;
  bool json;

  ServiceMessageListener serviceMessageListener;

  Service(this.verbose, this.json, this.serviceMessageListener) {
    this.state = 0;
  }

  void setState(int state) {
    this.state = state;
  }

  int getState() => state;
}