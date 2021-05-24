import '../service/adhoc_device.dart';
import '../service/constants.dart';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';


/// Class representing a remote Ble-capable device.
class BleAdHocDevice extends AdHocDevice {
  late int mtu;

  /// Creates an [BleAdHocDevice] object with the information of a discovered 
  /// device [device].
  BleAdHocDevice(DiscoveredDevice device) : super(
    label: '', address: '', name: device.name, mac: device.id, type: BLE,
  ) {
    this.mtu = MIN_MTU;
    this.address = 
      (BLUETOOTHLE_UUID + device.id.replaceAll(new RegExp(':'), ''))
        .toLowerCase();
  }

  /// Creates an [BleAdHocDevice] object with the information given by [map], 
  /// which contains the name of the device and its MAC address.
  /// 
  /// The map should contain a key 'deviceName' and 'macAddress'.
  BleAdHocDevice.fromMap(Map map) : super(
    label: '', address: '', name: map['deviceName'], mac: map['macAddress'], 
    type: BLE
  ) {
    this.mtu = MIN_MTU;
    this.address = 
      (BLUETOOTHLE_UUID + map['macAddress'].replaceAll(new RegExp(':'), ''))
        .toLowerCase();
  }

/*------------------------------Override methods------------------------------*/

  @override
  String toString() {
    return 'BleAdHocDevice{' +
              'mtu=$mtu' +
              ', label=$label' +
              ', uuid=$address' +
              ', name=$name' +
              ', mac=$mac' +
              ', type=$type' +
           '}';
  }
}
