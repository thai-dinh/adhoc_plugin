import 'package:adhoclibrary/src/datalink/service/service.dart';
import 'package:adhoclibrary/src/datalink/utils/utils.dart';


class AdHocDevice {
  bool directedConnected;
  String label;
  String deviceName;
  String macAddress;
  int type;

  AdHocDevice({
    String deviceName, this.label, this.macAddress, this.type,
    this.directedConnected
  }) {
    this.deviceName = Utils.checkString(deviceName);
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
              ', deviceName=' + deviceName +
              ', macAddress=' + macAddress.toString() +
              ', type=' + type.toString() +
              ', directedConnected=' + directedConnected.toString() +
           '}';
  }
}
