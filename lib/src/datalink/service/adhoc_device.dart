import 'package:AdHocLibrary/src/datalink/service/service.dart';

class AdHocDevice {
  bool _connected;
  String _label;
  String _deviceName;
  String _macAddress;
  int _type;

  /// Default constructor
  AdHocDevice() {
    this._connected = false;
    this._label = null;
    this._deviceName = null;
    this._macAddress = null;
    this._type = 0;
  }

  /// Named constructor
  AdHocDevice.init(String deviceName, this._macAddress, this._type, [this._label]) {
    this._deviceName = deviceName == null ? "" : deviceName;
    this._connected = true;
  }

  /// Factory named constructor
  factory AdHocDevice.connected(String deviceName, String macAddress, int type, 
                                String label, bool connected) {
    AdHocDevice device = new AdHocDevice.init(deviceName, macAddress, type, label);
    device._connected = connected;

    return device;
  }

  /// Factory named constructor
  factory AdHocDevice.label(String label) {
    AdHocDevice device = new AdHocDevice();
    device._connected = false;
    device._label = label;

    return device;
  }

  set directedConnected(bool connected) => this._connected = connected;

  set label(String label) =>  this._label = label;

  bool get directedConnected => _connected;

  String get deviceName => _deviceName;

  String get label => _label;

  String get macAddress => _macAddress;

  int get type => _type;

  String getStringType() {
    switch (_type) {
      case Service.BLUETOOTH:
        return "Bluetooth";
      case Service.WIFI:
        return "Wifi";
      default:
        return "UNKNOWN";
    }
  }

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