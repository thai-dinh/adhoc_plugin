import 'package:adhoclibrary/src/datalink/service/service.dart';
import 'package:adhoclibrary/src/datalink/utils/utils.dart';


class AdHocDevice {
  bool directedConnected;
  String label;
  String name;
  String mac;
  int type;

  AdHocDevice({
    String name, this.type, this.mac, this.label = '',
    this.directedConnected = false
  }) {
    this.name = Utils.checkString(name);
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
              ', name=' + name +
              ', mac=' + mac +
              ', type=' + type.toString() +
              ', directedConnected=' + directedConnected.toString() +
           '}';
  }
}
