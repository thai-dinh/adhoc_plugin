import '../service/adhoc_device.dart';
import '../service/constants.dart';
import '../utils/identifier.dart';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';


/// Class representing a remote Ble-capable device.
class BleAdHocDevice extends AdHocDevice {
  late int mtu;

  /// Creates a [BleAdHocDevice] object. 
  /// 
  /// The information of the created object is filled according to the 
  /// information given by [device].
  BleAdHocDevice(DiscoveredDevice device) : super(
    label: '', address: '', name: device.name, mac: Identifier(ble: device.id), 
    type: BLE,
  ) {
    this.mtu = MIN_MTU;
    this.address = 
      (BLUETOOTHLE_UUID + device.id.replaceAll(new RegExp(':'), ''))
        .toLowerCase();
  }

  /// Creates an [BleAdHocDevice] object.
  /// 
  /// The information of the created object is filled according to the 
  /// information given by [map].
  /// 
  /// The map should contain a key 'name' and 'mac'.
  BleAdHocDevice.fromMap(Map map) : super(
    label: '', address: '', name: map['name'], mac: map['mac'], 
    type: BLE
  ) {
    this.mtu = MIN_MTU;
    this.address = 
      (map['mac'] as Identifier).ble.replaceAll(new RegExp(':'), '');
    this.address = BLUETOOTHLE_UUID + this.address!.toLowerCase();
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
