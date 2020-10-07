import 'package:AdHocLibrary/src/datalink/service/adhoc_device.dart';
import 'package:AdHocLibrary/src/datalink/service/service.dart';

import 'package:flutter/services.dart';

class BluetoothAdHocDevice extends AdHocDevice {
  static const platform = const MethodChannel('ad.hoc.library.dev/bluetooth');

  String _uuidString;
  int _rssi;

  BluetoothAdHocDevice(String deviceName, String macAddress) 
    : super.init(deviceName, macAddress.toUpperCase(), Service.BLUETOOTH) {
    this._rssi = -1;
  }

  BluetoothAdHocDevice.rssi(String deviceName, String macAddress, this._rssi) 
    : super.init(deviceName, macAddress.toUpperCase(), Service.BLUETOOTH);

  factory BluetoothAdHocDevice.map(Map map) 
    => BluetoothAdHocDevice(map['deviceName'], map['macAddress']);

  String getUuid() => _uuidString;

  int getRssi() => _rssi;

  String toString() => "BluetoothAdHocDevice{" +
                        "uuidString='" + _uuidString + '\'' +
                        // ", uuid=" + uuid +
                        ", rssi=" + _rssi.toString() +
                        ", label='" + label + '\'' +
                        ", deviceName='" + deviceName + '\'' +
                        ", macAddress='" + macAddress + '\'' +
                        ", type=" + type.toString() +
                        '}';
}