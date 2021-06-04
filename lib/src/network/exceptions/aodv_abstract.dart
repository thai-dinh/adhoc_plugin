import 'dart:core';

/// Class signaling that an AODV exception has occurred.
class AodvAbstractException implements Exception {
  final String _message;

  /// Creates a [AodvAbstractException] object.
  ///
  /// Displays the exception [_message] if it is given, otherwise "Aodv
  /// exception triggered" is set.
  AodvAbstractException([this._message = 'Aodv exception triggered']);

  @override
  String toString() => _message;
}
