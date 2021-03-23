import 'dart:math';

import 'package:adhoc_plugin/src/datalink/utils/msg_adhoc.dart';
import 'package:adhoc_plugin/src/datalink/service/service.dart';


abstract class ServiceClient extends Service {
  static const String TAG = "[ServiceClient]";
  static const int _LOW = 1500;
  static const int _HIGH = 2500;

  int _attempts;
  int _backOffTime;
  int _timeOut;

  ServiceClient(
    bool verbose, int state, this._attempts, this._timeOut,
  ) : super(verbose, state) {
    this._backOffTime = new Random().nextInt(_HIGH - _LOW) + _LOW;
  }

/*------------------------------Getters & Setters-----------------------------*/

  int get attempts => _attempts;

  int get backOffTime => _backOffTime *= 2;

  int get timeOut => _timeOut;

/*-------------------------------Public methods-------------------------------*/

  void connect();

  void disconnect();

  void send(MessageAdHoc msg);
}
