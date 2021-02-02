import 'package:adhoclibrary/src/datalink/service/service_msg_listener.dart';


abstract class Service {
  static const int WIFI = 0;
  static const int BLUETOOTHLE = 1;

  static const int STATE_NONE = 0;
  static const int STATE_LISTENING = 1;
  static const int STATE_CONNECTING = 2;
  static const int STATE_CONNECTED = 3;

  bool v;
  int state;
  ServiceMessageListener serviceMessageListener;

  Service(this.v, this.state, this.serviceMessageListener);
}
