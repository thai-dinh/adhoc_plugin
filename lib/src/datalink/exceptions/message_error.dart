import 'dart:core';


class MessageErrorException implements Exception {
  String _message;

  MessageErrorException([this._message = 'Message error']);

  @override
  String toString() => _message;
}
