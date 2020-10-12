import 'dart:math';

import 'package:AdHocLibrary/datalink/service/service.dart';
import 'package:AdHocLibrary/datalink/service/service_message_listener.dart';

abstract class ServiceClient extends Service {
  static const int _LOW = 1500;
  static const int _HIGH = 2500;

  int _timeOut;
  int _attempts;

  int _backOffTime;

  ServiceClient(this._timeOut, this._attempts, bool verbose, bool json, 
    ServiceMessageListener listener) : super.init(verbose, json, listener) {
    this._backOffTime = new Random().nextInt(_HIGH - _LOW) + _LOW;
  }

  int get backOffTime => _backOffTime *= 2;

  void send() {
    if (state == Service.STATE_NONE) {

    } else {

    }
  }

  void listenInBackground() {
    if (state == Service.STATE_NONE) {
      
    } else {

    }
  }

  void stopListenInBackground() {
    if (state == Service.STATE_CONNECTED) {

    }
  }
}