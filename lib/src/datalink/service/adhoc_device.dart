import 'package:adhoclibrary/src/datalink/service/service.dart';

abstract class AdHocDevice {
  String _deviceName;
  int _deviceType;

  AdHocDevice([this._deviceName, this._deviceType]);

  String get deviceName => _deviceName;

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