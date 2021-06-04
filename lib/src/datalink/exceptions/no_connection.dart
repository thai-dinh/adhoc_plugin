import 'dart:core';

/// Class signaling that a No Connection exception has been triggered due to
/// invalid connection state with a remote peer.
class NoConnectionException implements Exception {
  final String _message;

  /// Creates a [NoConnectionException] object.
  ///
  /// Displays the exception [_message] if it is given, otherwise "Connection
  /// error" is set.
  NoConnectionException([this._message = 'Connection error']);

  @override
  String toString() => _message;
}
