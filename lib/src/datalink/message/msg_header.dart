class Header {
  int _deviceType;
  int _messageType;
  String _address;
  String _label;
  String _name;

  Header(this._messageType, this._label, this._name, [this._address]);

  set messageType(int messageType) => this._messageType = messageType;

  int get deviceType => _deviceType;

  int get messageType => _messageType;

  String get label => _label;

  String get name => _name;

  String get address => _address;

  String toJson() {
    return '{' +
              '"_deviceType" : "$_deviceType"' +
              '"_messageType" : "$_messageType"' +
              '"_address" : "$_address"' +
              '"_label" : "$_label"' +
              '"_name" : "$_name"' +
            '}';
  }

  @override
  String toString() {
    return 'Header{' +
              '_messageType=' + _messageType.toString() +
              ', label=' + _label +
              ', name=' + _name +
              ', address=' + _address +
            '}';
  }
}
