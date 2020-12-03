import 'package:adhoclibrary/src/datalink/service/adhoc_device.dart';
import 'package:adhoclibrary/src/datalink/service/service.dart';

class WifiAdHocDevice extends AdHocDevice {
  String ipAddress;
  int port;

  WifiAdHocDevice(String deviceName, String macAddress)
    : super(deviceName, macAddress, Service.WIFI) {
    
    this.ipAddress = "";
    this.port = 0;
  }

  @override
  String toString() {
    return 'WifiAdHocDevice' +
              'ipAddress=' + ipAddress +
              ', port=' + port.toString() +
              ', deviceName=' + deviceName +
              ', macAddress=' + macAddress +
              ', deviceType=' + deviceType.toString() +
           '}';
  }
}