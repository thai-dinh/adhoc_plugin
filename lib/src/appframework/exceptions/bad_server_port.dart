import 'dart:core';


/// Class signaling that an bad server port value exception has occurred.
class BadServerPortException implements Exception {
  String _message;

  /// Creates a [BadServerPortException] object.
  /// 
  /// Displays the exception [_message] if it is given, otherwise "Bad server 
  /// port" is set.
  BadServerPortException([this._message = 'Bad server port']);

  @override
  String toString() => _message;
}
