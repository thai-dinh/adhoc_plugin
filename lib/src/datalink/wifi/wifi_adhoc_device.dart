import 'package:adhoclibrary/src/datalink/service/adhoc_device.dart';
import 'package:adhoclibrary/src/datalink/service/service.dart';
import 'package:flutter_wifi_p2p/flutter_wifi_p2p.dart';


class WifiAdHocDevice extends AdHocDevice {
  String ipAddress;
  int port;

  WifiAdHocDevice(
    WifiP2pDevice device, {String ipAddress = '', String label = ''}
  ) : super(
    name: device.name, mac: device.mac, type: Service.WIFI
  ) {
    this.ipAddress = ipAddress;
    this.port = 0;
  }

  WifiAdHocDevice.fromWifiP2pDevice(WifiP2pDevice device) : super(
    name: device.name, mac: device.mac, type: Service.WIFI
  ) {
    this.ipAddress = ipAddress;
    this.port = 0;
  }

  @override
  String toString() {
    return 'WifiAdHocDevice' +
              'ipAddress=' + ipAddress +
              ', port=' + port.toString() +
              ', label=' + label +
              ', name' + name +
              ', mac' + mac +
              ', type' + type.toString() +
           '}';
  }
}
