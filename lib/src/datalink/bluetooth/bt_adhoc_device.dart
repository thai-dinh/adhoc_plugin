import 'package:AdHocLibrary/src/datalink/service/adhoc_device.dart';

class BluetoothAdHocDevice extends AdHocDevice {
  String _uuidString;
  int _rssi;

  BluetoothAdHocDevice() : super() {
    this._rssi = -1;
  }

  BluetoothAdHocDevice.rssi(this._rssi) : super();

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