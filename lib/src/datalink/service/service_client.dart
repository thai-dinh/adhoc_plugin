import 'dart:math';

import 'package:adhoc_plugin/src/datalink/service/constants.dart';
import 'package:adhoc_plugin/src/datalink/utils/msg_adhoc.dart';
import 'package:adhoc_plugin/src/datalink/service/service.dart';


abstract class ServiceClient extends Service {
  static const String TAG = "[ServiceClient]";

  int _attempts;
  int _backOffTime;
  int _timeOut;

  ServiceClient(
    bool verbose, this._attempts, this._timeOut,
  ) : super(verbose, STATE_NONE) {
    this._backOffTime = new Random().nextInt(HIGH - LOW) + LOW;
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
