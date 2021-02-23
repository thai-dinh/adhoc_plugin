class ConnectStatus {
  int _status;
  String _address;
  Object _error;

  ConnectStatus(this._status, {String address, dynamic error}) {
    this._address = address;
    this._error = error;
  }

  int get status => _status;

  String get address => _address;

  dynamic get error => _error;
}
