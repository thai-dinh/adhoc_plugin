import 'dart:core';


class AodvUnknownDestException implements Exception {
  String _message;

  AodvUnknownDestException([this._message = 'Bad duration']);

  @override
  String toString() => _message;
}