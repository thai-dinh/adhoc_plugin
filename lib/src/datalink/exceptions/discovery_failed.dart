import 'dart:core';


class DiscoveryFailedException implements Exception {
  String _message;

  DiscoveryFailedException([this._message = 'Discovery process failed']);

  @override
  String toString() => _message;
}
