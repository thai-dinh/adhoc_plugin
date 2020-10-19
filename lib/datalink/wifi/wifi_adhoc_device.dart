import 'package:AdHocLibrary/datalink/service/adhoc_device.dart';
import 'package:AdHocLibrary/datalink/service/service.dart';

class WifiAdHocDevice extends AdHocDevice {
  String _ipAddress;
  int _port;

  WifiAdHocDevice(String deviceName, String macAddress) 
    : super.init(deviceName, macAddress.toUpperCase(), Service.WIFI) {
    this._ipAddress = '';
    this._port = 0;
  }

  WifiAdHocDevice.ip(String deviceName, String macAddress, int type, String label, 
                     String ipAddress) 
    : super.init(deviceName, macAddress, type, label) {
      this._ipAddress = ipAddress;
      this._port = 0;
  }

  set ipAddress(String ipAddress) => _ipAddress = ipAddress; 

  set port(int port) => _port = port;

  String get ipAddress => _ipAddress;

  int get port => _port;

  String toString() {
    return 'WifiAdHocDevice{' +
            'ipAddress=' + _ipAddress + '\'' +
            ', port=' + _port.toString() +
            ', label=' + label + '\'' +
            ', deviceName=' + deviceName + '\'' +
            ', macAddress=' + macAddress + '\'' +
            ', type=' + type.toString() +
            '}';
  }
}