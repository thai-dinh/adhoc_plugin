import 'package:adhoclibrary/src/datalink/ble/ble_utils.dart';
import 'package:adhoclibrary/src/datalink/service/adhoc_device.dart';
import 'package:adhoclibrary/src/datalink/service/service.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';


class BleAdHocDevice extends AdHocDevice {
  int mtu;

  BleAdHocDevice(DiscoveredDevice device) : super(
    deviceName: device.name,
    macAddress: device.id,
    type: Service.BLUETOOTHLE
  ) {
    this.mtu = BleUtils.MIN_MTU;
  }

  BleAdHocDevice.fromMap(Map map) : super(
    deviceName: map['deviceName'],
    macAddress: map['macAddress'], 
    type: Service.BLUETOOTHLE
  ) {
    this.mtu = BleUtils.MIN_MTU;
  }

  @override
  String toString() {
    return 'BleAdHocDevice{' +
              'mtu=' + mtu.toString() +
              'label=' + label +
              ', deviceName' + deviceName +
              ', macAddress' + macAddress.toString() +
              ', type' + type.toString() +
           '}';
  }
}
