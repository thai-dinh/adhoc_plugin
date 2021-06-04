import 'dart:core';

/// Class signaling that a AODV unknown destination route exception has occurred.
class AodvUnknownDestException implements Exception {
  final String _message;

  /// Creates a [AodvUnknownDestException] object.
  ///
  /// Displays the exception [_message] if it is given, otherwise "Aodv unknown
  /// destination exception triggered" is set.
  AodvUnknownDestException(
      [this._message = 'Aodv unknown destination exception triggered']);

  @override
  String toString() => _message;
}
