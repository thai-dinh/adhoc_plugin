import 'dart:core';


/// Class signaling that a Device Failure exception has been triggered due to 
/// invalid state of the device.
class DeviceFailureException implements Exception {
  String _message;

  /// Creates a [DeviceFailureException] object.
  /// 
  /// Displays the exception [_message] if it is given, otherwise "Device 
  /// failure" is set.
  DeviceFailureException([this._message = 'Device failure']);

  @override
  String toString() => _message;
}
