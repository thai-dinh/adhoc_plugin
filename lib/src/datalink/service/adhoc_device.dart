import 'package:AdHocLibrary/src/datalink/service/service.dart';

class AdHocDevice {
  bool _connected;

  String label;
  String deviceName;
  String macAddress;
  int type;

  /// Default constructor
  AdHocDevice() {
    this._connected = false;
    this.label = null;
    this.deviceName = null;
    this.macAddress = null;
    this.type = 0;
  }

  /// Named constructor
  AdHocDevice.init(String deviceName, this.macAddress, this.type, [this.label]) {
    this.deviceName = deviceName == null ? "" : deviceName;
    this._connected = true;
  }

  /// Factory named constructor
  factory AdHocDevice.connected(String deviceName, String macAddress, int type, 
                                String label, bool connected) {
    AdHocDevice device = 
      new AdHocDevice.init(deviceName, macAddress, type, label);
    device._connected = connected;

    return device;
  }

  /// Factory named constructor
  factory AdHocDevice.label(String label) {
    AdHocDevice device = new AdHocDevice();
    device._connected = false;
    device.label = label;

    return device;
  }

  void setLabel(String label) {
    this.label = label;
  }

  void setDirectedConnected(bool connected) {
    this._connected = connected;
  }

  String getLabel() => label;

  String getMacAddress() => macAddress;

  String getDeviceName() => deviceName;

  int getType() => type;

  String getStringType() {
    switch (type) {
      case Service.BLUETOOTH:
        return "Bluetooth";
      case Service.WIFI:
        return "Wifi";
      default:
        return "UNKNOWN";
    }
  }

  bool isDirectedConnected() => _connected;

  String toString() {
      return "AdHocDevice{" +
              "label='" + label + '\'' +
              ", deviceName='" + deviceName + '\'' +
              ", macAddress='" + macAddress + '\'' +
              ", type=" + getStringType() +
              ", connected=" + _connected.toString() +
              '}';
  }
}