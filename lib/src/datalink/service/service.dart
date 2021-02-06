import 'package:adhoclibrary/src/datalink/utils/msg_adhoc.dart';
import 'package:adhoclibrary/src/datalink/utils/utils.dart';


abstract class Service {
  static const String TAG = "[Service]";

  static const WIFI = 0;
  static const BLUETOOTHLE = 1;

  static const STATE_NONE = 0;
  static const STATE_LISTENING = 1;
  static const STATE_CONNECTING = 2;
  static const STATE_CONNECTED = 3;

  int _state;

  bool v;

  Service(this.v, this._state);

/*------------------------------Getters & Setters-----------------------------*/

  set state(int state) {
    if (v) Utils.log(TAG, 'state: $_state -> $state');
    _state = state;
  }

  int get state => _state;

/*-------------------------------Public methods-------------------------------*/

  void listen(
    void onMessage(MessageAdHoc message), void onError(dynamic error)
  );

  void stopListening();
}
