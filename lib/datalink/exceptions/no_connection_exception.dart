import 'dart:core';

class NoConnectionException implements Exception{
  String _message;

  NoConnectionException([this._message = 'Connection failed']);

  @override
  String toString() {
    return _message;
  }
}