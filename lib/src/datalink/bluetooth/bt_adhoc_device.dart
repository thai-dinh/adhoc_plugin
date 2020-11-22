import 'package:adhoclibrary/src/datalink/service/adhoc_device.dart';
import 'package:adhoclibrary/src/datalink/service/service.dart';
import 'package:adhoclibrary/src/datalink/utils/utils.dart';

class BluetoothAdHocDevice extends AdHocDevice {
  String _uuidString;
  int _rssi;

  BluetoothAdHocDevice(String deviceName, String macAddress) 
    : super.init(deviceName, macAddress.toUpperCase(), Service.BLUETOOTH)
  {
    this._uuidString = UUID + macAddress.replaceAll(':', '').toLowerCase();
    this._rssi = -1;
  }

  BluetoothAdHocDevice.rssi(String deviceName, String macAddress, this._rssi) 
    : super.init(deviceName, macAddress.toUpperCase(), Service.BLUETOOTH);

  factory BluetoothAdHocDevice.map(Map map) {
    return BluetoothAdHocDevice(map['deviceName'], map['macAddress']);
  }

  String get uuid => _uuidString;

  int get rssi => _rssi;
}