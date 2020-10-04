class Header {
  int type;
  String label;
  String name;

  String _address;
  String _mac;
  int _deviceType;

  Header();

  Header.init(this.type, this.label, this.name, 
             [this._mac, this._address, this._deviceType]);

  void setType(int type) {
    this.type = type;
  }

  int getType() => type;

  String getLabel() => label;

  String getName() => name;

  String getAddress() => _address;

  String getMac() => _mac;

  int getDeviceType() => _deviceType;

  String toString() => "Header{" +
                        "type=" + type.toString() +
                        ", label='" + label + '\'' +
                        ", name='" + name + '\'' +
                        ", address='" + _address.toString() + '\'' +
                        ", mac='" + _mac.toString() + '\'' +
                        '}';
}