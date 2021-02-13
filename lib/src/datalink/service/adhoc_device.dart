import 'package:adhoclibrary/src/datalink/service/service.dart';
import 'package:adhoclibrary/src/datalink/utils/utils.dart';
import 'package:meta/meta.dart';


class AdHocDevice {
  bool directedConnected;
  String label;
  String name;
  String mac;
  String address;
  int type;

  AdHocDevice({
    @required String name, @required this.type, @required this.mac,
    this.address = '', this.label = '', this.directedConnected = false
  }) {
    this.name = Utils.checkString(name);
    this.address = Utils.checkString(address);
    this.label = Utils.checkString(label);
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
              ', address=' + address +
              ', type=' + type.toString() +
              ', directedConnected=' + directedConnected.toString() +
           '}';
  }
}
