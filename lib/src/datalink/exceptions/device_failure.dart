import 'dart:core';

class DeviceFailureException implements Exception {
  String _message;

  DeviceFailureException([this._message = 'Device failure event']);

  @override
  String toString() => _message;
}
