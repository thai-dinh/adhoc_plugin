import 'dart:core';


/// Class signaling that verification of a certificae chain exception has 
/// occurred.
class VerificationFailedException implements Exception {
  String _message;

  /// Creates a [VerificationFailedException] object.
  /// 
  /// Displays the exception [_message] if it is given, otherwise "Verification 
  /// of the certificate chain failed" is set.
  VerificationFailedException(
    [this._message = 'Verification of the certificate chain failed']
  );

  @override
  String toString() => _message;
}