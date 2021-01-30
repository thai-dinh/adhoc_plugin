import 'dart:core';

class DeviceNotFoundException implements Exception {
  String _message;

  DeviceNotFoundException([this._message = 'Device not found']);

  @override
  String toString() => _message;
}
