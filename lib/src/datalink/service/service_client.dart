import 'dart:math';

import 'package:adhoclibrary/src/datalink/service/service.dart';
import 'package:adhoclibrary/src/datalink/message/msg_adhoc.dart';

abstract class ServiceClient extends Service {
  static const int _LOW = 1500;
  static const int _HIGH = 2500;

  int _attempts;
  int _backOffTime;
  int _timeOut;

  ServiceClient(int state, this._attempts, this._timeOut) : super(state) {
    this._backOffTime = new Random().nextInt(_HIGH - _LOW) + _LOW;
  }

  int get attempts => _attempts;

  int get backOffTime => _backOffTime *= 2;

  int get timeOut => _timeOut;

  void connect();

  void cancelConnection();

  void sendMessage(MessageAdHoc msg);

  MessageAdHoc receiveMessage();
}
