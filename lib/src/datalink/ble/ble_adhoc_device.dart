import 'package:adhoclibrary/src/datalink/ble/ble_utils.dart';
import 'package:adhoclibrary/src/datalink/service/adhoc_device.dart';
import 'package:adhoclibrary/src/datalink/service/service.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';


class BleAdHocDevice extends AdHocDevice {
  int mtu;
  String _uuid;

  BleAdHocDevice(DiscoveredDevice device) : super(
    name: device.name,
    mac: device.id,
    type: Service.BLUETOOTHLE,
  ) {
    this.mtu = BleUtils.MIN_MTU;
    this._uuid = 
      BleUtils.BLUETOOTHLE_UUID + device.id.replaceAll(new RegExp(':'), '');
  }

  BleAdHocDevice.fromMap(Map map) : super(
    name: map['deviceName'],
    mac: map['macAddress'], 
    type: Service.BLUETOOTHLE
  ) {
    this.mtu = BleUtils.MIN_MTU;
    this._uuid = BleUtils.BLUETOOTHLE_UUID + 
      map['macAddress'].replaceAll(new RegExp(':'), '').toLowerCase();
  }

  String get uuid => _uuid;

  @override
  String toString() {
    return 'BleAdHocDevice{' +
              'mtu=' + mtu.toString() +
              ', uuid=' + uuid +
              ', label=' + label +
              ', name' + name +
              ', mac' + mac.toString() +
              ', type' + type.toString() +
           '}';
  }
}
