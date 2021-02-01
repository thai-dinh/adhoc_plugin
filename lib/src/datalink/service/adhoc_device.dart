import 'package:adhoclibrary/src/datalink/service/service.dart';


abstract class AdHocDevice {
  String label;
  String deviceName;
  String macAddress;
  int type;

  AdHocDevice({String deviceName, this.label, this.macAddress, this.type}) {
    this.deviceName = _checkName(deviceName);
  }

  String _checkName(String deviceName) {
    return deviceName == null ? '' : deviceName;
  }

  String typeAsString() {
    switch (type) {
      case Service.BLUETOOTHLE:
        return "BluetoothLE";
      case Service.WIFI:
        return "Wifi";
      default:
        return "UNKNOWN";
    }
  }

  @override
  String toString() {
    return 'AdHocDevice{' +
              'label=' + label +
              ', deviceName' + deviceName +
              ', macAddress' + macAddress.toString() +
              ', type' + type.toString() +
           '}';
  }
}
