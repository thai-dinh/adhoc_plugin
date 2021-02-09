import 'package:adhoclibrary/src/datalink/service/discovery_event.dart';
import 'package:adhoclibrary/src/datalink/utils/utils.dart';


abstract class Service {
  static const String TAG = "[Service]";

  static const WIFI = 0;
  static const BLUETOOTHLE = 1;

  static const STATE_NONE = 0;
  static const STATE_LISTENING = 1;
  static const STATE_CONNECTING = 2;
  static const STATE_CONNECTED = 3;

  static const MESSAGE_RECEIVED = 6;
  static const DEVICE_DISCOVERED = 7;
  static const DISCOVERY_STARTED = 8;
  static const DISCOVERY_END = 9;
  static const CONNECTION_PERFORMED = 10;
  static const CONNECTION_CLOSED = 11;

  int _state;

  void Function(DiscoveryEvent) onEvent;
  void Function(dynamic) onError;
  bool v;

  Service(this.v, this._state, this.onEvent, this.onError);

/*------------------------------Getters & Setters-----------------------------*/

  set state(int state) {
    if (v) Utils.log(TAG, 'state: $_state -> $state');
    _state = state;
  }

  int get state => _state;

/*-------------------------------Public methods-------------------------------*/

  void listen();

  void stopListening();
}
