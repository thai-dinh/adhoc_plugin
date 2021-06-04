import 'dart:core';

/// Class signaling that a AODV Message exception has occurred during processing
/// of a message.
class AodvMessageException implements Exception {
  final String _message;

  /// Creates a [AodvMessageException] object.
  ///
  /// Displays the exception [_message] if it is given, otherwise "Aodv message
  /// exception triggered" is set.
  AodvMessageException([this._message = 'Aodv message exception triggered']);

  @override
  String toString() => _message;
}
