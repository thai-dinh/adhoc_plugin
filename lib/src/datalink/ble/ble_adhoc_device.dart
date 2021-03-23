import 'package:adhoc_plugin/src/datalink/ble/ble_constants.dart';
import 'package:adhoc_plugin/src/datalink/service/adhoc_device.dart';
import 'package:adhoc_plugin/src/datalink/service/service.dart';
import 'package:adhoc_plugin/src/datalink/utils/identifier.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';


class BleAdHocDevice extends AdHocDevice {
  int mtu;

  BleAdHocDevice(DiscoveredDevice device) : super(
    name: device.name, mac: Identifier(ble: device.id), type: Service.BLUETOOTHLE,
  ) {
    this.mtu = MIN_MTU;
    this.address = 
      (BLUETOOTHLE_UUID + device.id.replaceAll(new RegExp(':'), '')).toLowerCase();
  }

  BleAdHocDevice.fromMap(Map map) : super(
    name: map['deviceName'], mac: map['macAddress'], type: Service.BLUETOOTHLE
  ) {
    this.mtu = MIN_MTU;
    this.address = 
      (BLUETOOTHLE_UUID + map['macAddress'].replaceAll(new RegExp(':'), '')).toLowerCase();
  }

/*------------------------------Getters & Setters-----------------------------*/

  String get uuid => address;

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
