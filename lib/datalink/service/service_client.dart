import 'dart:math';

import 'package:AdHocLibrary/datalink/service/service.dart';

abstract class ServiceClient extends Service {
  static const int _LOW = 1500;
  static const int _HIGH = 2500;

  int _attempts;
  int _backOffTime;
  int _timeOut;

  ServiceClient(this._attempts, this._timeOut) {
    this._backOffTime = new Random().nextInt(_HIGH - _LOW) + _LOW;
  }

  int get attempts => _attempts;

  int get backOffTime => _backOffTime *= 2;

  int get timeOut => _timeOut;
}