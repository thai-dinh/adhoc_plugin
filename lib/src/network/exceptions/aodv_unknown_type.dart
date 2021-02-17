import 'dart:core';


class AodvUnknownTypeException implements Exception {
  String _message;

  AodvUnknownTypeException([this._message = 'Bad duration']);

  @override
  String toString() => _message;
}