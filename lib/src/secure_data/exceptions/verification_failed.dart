import 'dart:core';


class VerificationFailedException implements Exception {
  String _message;

  VerificationFailedException(
    [this._message = 'Verification of the certificate chain failed.']
  );

  @override
  String toString() => _message;
}