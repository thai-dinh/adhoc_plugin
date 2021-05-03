import 'dart:async';

import 'package:adhoc_plugin/src/datalink/service/adhoc_event.dart';
import 'package:adhoc_plugin/src/datalink/service/constants.dart';
import 'package:adhoc_plugin/src/datalink/utils/utils.dart';


abstract class Service {
  static const String TAG = "[Service]";

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
