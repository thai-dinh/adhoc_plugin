import 'dart:core';


class AodvAbstractException implements Exception {
  String _message;

  AodvAbstractException([this._message = 'Bad duration']);

  @override
  String toString() => _message;
}