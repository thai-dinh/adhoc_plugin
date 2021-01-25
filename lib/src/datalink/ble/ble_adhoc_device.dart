import 'package:adhoclibrary/src/datalink/ble/ble_util.dart';
import 'package:adhoclibrary/src/datalink/service/adhoc_device.dart';
import 'package:adhoclibrary/src/datalink/service/service.dart';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BleAdHocDevice extends AdHocDevice {
  int _rssi;

  int mtu;

  BleAdHocDevice(DiscoveredDevice device) 
    : super(device.name, device.id, Service.BLUETOOTH) {

    this._rssi = device.rssi;
    this.mtu = MIN_MTU;
  }

  BleAdHocDevice.fromMap(Map map) 
    : super(map['deviceName'], map['macAddress'], Service.BLUETOOTH) {

    this.mtu = MIN_MTU;
  }

  int get rssi => _rssi;

  @override
  String toString() {
    return 'BleAdHocDevice{' +
              'mtu=' + mtu.toString() +
              'rssi=' + _rssi.toString() +
           '}';
  }
}
