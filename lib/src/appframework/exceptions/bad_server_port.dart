import 'dart:core';

class BadServerPortException implements Exception {
  String _message;

  BadServerPortException([this._message = 'Bad server port']);

  @override
  String toString() => _message;
}
