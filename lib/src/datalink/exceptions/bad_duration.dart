import 'dart:core';

class BadDurationException implements Exception {
  String _message;

  BadDurationException([this._message = 'Bad duration']);

  @override
  String toString() => _message;
}
