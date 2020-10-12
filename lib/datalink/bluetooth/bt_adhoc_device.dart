import 'package:AdHocLibrary/datalink/service/adhoc_device.dart';
import 'package:AdHocLibrary/datalink/service/service.dart';

class BluetoothAdHocDevice extends AdHocDevice {
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

  String get uuid => _uuidString;

  int get rssi => _rssi;

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