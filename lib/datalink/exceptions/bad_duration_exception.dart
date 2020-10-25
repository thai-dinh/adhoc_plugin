import 'dart:core';

class BadDurationException implements Exception{
  String _message;

  BadDurationException([this._message = 'Bad duration time']);

  @override
  String toString() {
    return _message;
  }
}