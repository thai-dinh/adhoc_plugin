import 'package:adhoclibrary/src/datalink/service/service.dart';

abstract class AdHocDevice {
  String _deviceName;
  String _macAddress;
  int _deviceType;

  AdHocDevice([this._deviceName, this._macAddress, this._deviceType]);

  String get deviceName => _deviceName;

  String get macAddress => _macAddress;

  int get deviceType => _deviceType;

  String deviceTypeStr() {
    switch (_deviceType) {
      case Service.BLUETOOTH:
        return "Bluetooth";
      case Service.WIFI:
        return "Wifi";
      default:
        return "UNKNOWN";
    }
  }
}
