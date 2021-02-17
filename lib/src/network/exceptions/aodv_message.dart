import 'dart:core';


class AodvMessageException implements Exception {
  String _message;

  AodvMessageException([this._message = 'Bad duration']);

  @override
  String toString() => _message;
}