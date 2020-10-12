import 'package:AdHocLibrary/datalink/service/adhoc_device.dart';
import 'package:AdHocLibrary/datalink/service/service.dart';

class WifiAdHocDevice extends AdHocDevice {
  String ipAddress;
  int port;

  WifiAdHocDevice(String deviceName, String macAddress) 
    : super.init(deviceName, macAddress.toUpperCase(), Service.WIFI) {
    this.ipAddress = '';
    this.port = 0;
  }

  WifiAdHocDevice.ip(String deviceName, String macAddress, int type, String label, 
                     String ipAddress) 
    : super.init(deviceName, macAddress, type, label) {
      this.ipAddress = ipAddress;
      this.port = 0;
  }

  String toString() {
    return 'WifiAdHocDevice{' +
            'ipAddress=' + ipAddress + '\'' +
            ', port=' + port.toString() +
            ', label=' + label + '\'' +
            ', deviceName=' + deviceName + '\'' +
            ', macAddress=' + macAddress + '\'' +
            ', type=' + type.toString() +
            '}';
  }
}