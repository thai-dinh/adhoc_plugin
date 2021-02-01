abstract class Service {
  static const int WIFI = 0;
  static const int BLUETOOTHLE = 1;

  static const int STATE_NONE = 0;
  static const int STATE_LISTENING = 1;
  static const int STATE_CONNECTING = 2;
  static const int STATE_CONNECTED = 3;

  static const int MESSAGE_READ = 4;

  static const int CONNECTION_ABORTED = 5;
  static const int CONNECTION_PERFORMED = 6;
  static const int CONNECTION_FAILED = 7;

  static const int LOG_EXCEPTION = 8;
  static const int MESSAGE_EXCEPTION = 9;
  static const int NETWORK_UNREACHABLE = 10;

  bool v;
  int state;

  Service(this.v, this.state);
}
