import 'package:adhoc_plugin/src/datalink/service/adhoc_device.dart';
import 'package:adhoc_plugin/src/datalink/service/constants.dart';
import 'package:adhoc_plugin/src/datalink/utils/identifier.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

/// Class representing a remote Ble-capable device.
class BleAdHocDevice extends AdHocDevice {
  late int mtu;

  /// Creates a [BleAdHocDevice] object.
  ///
  /// The information of the created object is filled according to the
  /// information given by [device].
  BleAdHocDevice(DiscoveredDevice device) : super(
    label: '',
    address: '',
    name: device.name,
    mac: Identifier(ble: device.id),
    type: BLE,
  ) {
    mtu = MIN_MTU;
    address = device.id.replaceAll(RegExp(':'), '').toLowerCase();
    address = BLUETOOTHLE_UUID + address!;
  }

  /// Creates an [BleAdHocDevice] object.
  ///
  /// The information of the created object is filled according to the
  /// information given by [map].
  ///
  /// The map should contain a key 'name' and 'mac'.
  BleAdHocDevice.fromMap(Map<dynamic, dynamic> map) : super(
    label: '',
    address: '',
    name: map['name'] as String,
    mac: map['mac'] as Identifier,
    type: BLE
  ) {
    mtu = MIN_MTU;
    address = (map['mac'] as Identifier).ble.replaceAll(RegExp(':'), '');
    address = BLUETOOTHLE_UUID + address!.toLowerCase();
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
