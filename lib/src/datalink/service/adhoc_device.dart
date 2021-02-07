import 'package:adhoclibrary/src/datalink/service/service.dart';
import 'package:adhoclibrary/src/datalink/utils/utils.dart';
import 'package:flutter/material.dart';


class AdHocDevice {
  bool directedConnected;
  String label;
  String name;
  String ulid;
  String mac;
  int type;

  AdHocDevice({
    @required String name, @required this.type, this.mac,
    this.label = '', this.ulid = '', this.directedConnected = false
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
              ', ulid=' + ulid +
              ', mac=' + mac +
              ', type=' + type.toString() +
              ', directedConnected=' + directedConnected.toString() +
           '}';
  }
}
