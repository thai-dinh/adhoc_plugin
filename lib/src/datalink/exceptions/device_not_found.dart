import 'dart:core';


/// Class signaling that a Device Not Found exception has been triggered due to 
/// not finding the AdHocDevice object of a remote peer.
class DeviceNotFoundException implements Exception {
  final String _message;

  /// Creates a [DeviceNotFoundException] object.
  /// 
  /// Displays the exception [_message] if it is given, otherwise "Device not 
  /// found" is set.
  DeviceNotFoundException([this._message = 'Device not found']);

  @override
  String toString() => _message;
}
