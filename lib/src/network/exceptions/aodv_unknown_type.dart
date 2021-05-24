import 'dart:core';


/// Class signaling that a AODV unknown type exception has occurred.
class AodvUnknownTypeException implements Exception {
  String _message;

  /// Creates a [AodvAbstractException] object.
  /// 
  /// Displays the exception [_message] if it is given, otherwise "Aodv unknow 
  /// type exception triggered" is set.
  AodvUnknownTypeException(
    [this._message = 'Aodv unknow type exception triggered']
  );

  @override
  String toString() => _message;
}