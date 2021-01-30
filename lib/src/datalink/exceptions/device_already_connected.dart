import 'dart:core';

class DeviceAlreadyConnectedException implements Exception {
  String _message;

  DeviceAlreadyConnectedException([this._message = 'Device already connectd']);

  @override
  String toString() => _message;
}
