import 'package:adhoclibrary/src/datalink/ble/ble_utils.dart';
import 'package:adhoclibrary/src/datalink/service/adhoc_device.dart';
import 'package:adhoclibrary/src/datalink/service/service.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';


class BleAdHocDevice extends AdHocDevice {
  int mtu;

  BleAdHocDevice(DiscoveredDevice device) : super(
    name: device.name,
    mac: device.id,
    type: Service.BLUETOOTHLE,
  ) {
    this.mtu = BleUtils.MIN_MTU;
  }

  BleAdHocDevice.fromMap(Map map) : super(
    name: map['deviceName'],
    mac: map['macAddress'], 
    type: Service.BLUETOOTHLE
  ) {
    this.mtu = BleUtils.MIN_MTU;
  }

  @override
  String toString() {
    return 'BleAdHocDevice{' +
              'mtu=' + mtu.toString() +
              ', label=' + label +
              ', name' + name +
              ', mac' + mac.toString() +
              ', type' + type.toString() +
           '}';
  }
}
