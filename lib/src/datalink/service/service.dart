import 'dart:async';

import 'package:adhoc_plugin/src/datalink/service/adhoc_event.dart';
import 'package:adhoc_plugin/src/datalink/utils/utils.dart';


abstract class Service {
  static const String TAG = "[Service]";

  static const WIFI = 0;
  static const BLUETOOTHLE = 1;

  static const STATE_NONE = 0;
  static const STATE_CONNECTED = 1;
  static const STATE_CONNECTING = 2;
  static const STATE_LISTENING = 3;

  static const DISCOVERY_START = 4;
  static const DISCOVERY_END = 5;
  static const DEVICE_DISCOVERED = 6;

  static const MESSAGE_RECEIVED = 7;
  static const CONNECTION_PERFORMED = 8;
  static const CONNECTION_ABORTED = 9;
  static const CONNECTION_EXCEPTION = 10;

  int _state;

  bool verbose;
  StreamController<AdHocEvent> controller;

  Service(this.verbose, this._state) {
    controller = StreamController<AdHocEvent>.broadcast();
  }

/*------------------------------Getters & Setters-----------------------------*/

  set state(int state) {
    if (verbose)
      log(TAG, 'state: ${_stateToString(_state)} -> ${_stateToString(state)}');
    _state = state;
  }

  int get state => _state;

  Stream<AdHocEvent> get adhocEvent => controller.stream;

/*-------------------------------Public methods-------------------------------*/

  void listen();

  void stopListening() => controller.close();

/*-----------------------------Private methods-------------------------------*/

  String _stateToString(int state) {
    switch (state) {
      case STATE_CONNECTED:
        return 'Connected';
      case STATE_CONNECTING:
        return 'Connecting';
      case STATE_LISTENING:
        return 'Listening';
      default:
        return 'None';
    }
  }
}
