import 'dart:core';

/// Class signaling that a group member is not reachable
class DestinationUnreachableException implements Exception {
  final String _message;

  /// Creates a [DestinationUnreachableException] object.
  ///
  /// Displays the exception [_message] if it is given, otherwise "Destination
  /// not reachable" is set.
  DestinationUnreachableException([this._message = 'Destination not reachable']);

  @override
  String toString() => _message;
}
