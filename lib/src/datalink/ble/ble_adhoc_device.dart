import 'package:adhoc_plugin/src/datalink/service/adhoc_device.dart';
import 'package:adhoc_plugin/src/datalink/service/constants.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';


/// Class representing a remote BLE-capable device.
class BleAdHocDevice extends AdHocDevice {
  late int mtu;

  /// Initialize a newly created BleAdHocDevice representing a remote 
  /// BLE-capable device with information given by discovered [device].
  BleAdHocDevice(DiscoveredDevice device) : super(
    name: device.name, mac: device.id, type: BLE,
  ) {
    this.mtu = MIN_MTU;
    this.address = (BLUETOOTHLE_UUID + device.id.replaceAll(new RegExp(':'), '')).toLowerCase();
  }

  /// Initialize a newly created BleAdHocDevice representing a remote 
  /// BLE-capable device with information given by [map].
  BleAdHocDevice.fromMap(Map map) : super(
    name: map['deviceName'], mac: map['macAddress'], type: BLE
  ) {
    this.mtu = MIN_MTU;
    this.address = (BLUETOOTHLE_UUID + map['macAddress'].replaceAll(new RegExp(':'), '')).toLowerCase();
  }

/*------------------------------Getters & Setters-----------------------------*/

  /// Return the UUID of the remote BLE-capable device.
  String? get uuid => address;

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
