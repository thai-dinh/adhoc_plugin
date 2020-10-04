class BluetoothDevice {
  final String _macAddress;
  final String _deviceName;
  final int _type;

  BluetoothDevice(this._macAddress, this._deviceName, this._type);

  String getAddress() => _macAddress;

  String getName() => _deviceName;

  int getType() => _type;

  static BluetoothDevice fromJson(dynamic json) {
    return BluetoothDevice(json['address'], json['name'], json['type']);
  }
}