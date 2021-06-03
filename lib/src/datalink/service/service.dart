import 'dart:async';

import 'package:adhoc_plugin/src/datalink/service/adhoc_event.dart';
import 'package:adhoc_plugin/src/datalink/service/constants.dart';
import 'package:adhoc_plugin/src/datalink/utils/utils.dart';


/// Abstract superclass providing common interfaces for the services 
/// 'ServiceClient' and 'ServiceServer' classes.
abstract class Service {
  static const String TAG = "[Service]";

  final bool verbose;

  late int _state;

  late StreamController<AdHocEvent> controller;

  /// Creates a [Service] object.
  /// 
  /// The debug/verbose mode is set if [verbose] is true.
  Service(this.verbose) {
    _state = STATE_NONE;
    controller = StreamController<AdHocEvent>.broadcast();
  }

/*------------------------------Getters & Setters-----------------------------*/

  /// Sets the state of the connection to [state].
  set state(int state) {
    if (verbose) {
      log(TAG, 'state: ${_stateToString(_state)} -> ${_stateToString(state)}');
    }

    _state = state;
  }

  /// State of the connection.
  int get state => _state;

  /// Ad hoc event stream containing events such as messages received, connection
  /// performed, or aborted.
  Stream<AdHocEvent> get eventStream => controller.stream;

/*-------------------------------Public methods-------------------------------*/

  /// Starts the listening process for ad hoc events.
  void listen();

  /// Stops the listening process for ad hoc events.
  void stopListening() => controller.close();

/*-----------------------------Private methods-------------------------------*/

  /// Gets the state of the connection as a [String].
  /// 
  /// Returns the current state of the connection. The possible outcomes are
  /// 'Connected', 'Connecting', 'Listening', and 'None'.
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
