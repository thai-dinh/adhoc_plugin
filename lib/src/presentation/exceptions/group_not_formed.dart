import 'dart:core';


/// Class signaling that verification of a certificae chain exception has 
/// occurred.
class GroupNotFormedException implements Exception {
  String _message;

  /// Creates a [GroupNotFormedException] object.
  /// 
  /// Displays the exception [_message] if it is given, otherwise "Not part of 
  /// any secure group" is set.
  GroupNotFormedException(
    [this._message = 'Not part of any secure group']
  );

  @override
  String toString() => _message;
}