import 'package:adhoclibrary/adhoclibrary.dart';
import 'package:flutter_wifi_p2p/flutter_wifi_p2p.dart';


class WifiAdHocDevice extends AdHocDevice {
  int port;

  WifiAdHocDevice(
    WifiP2pDevice device, {String ipAddress = '', String label = ''}
  ) : super(
    name: device.name, mac: device.mac, type: Service.WIFI
  ) {
    this.address = checkString(ipAddress);
    this.label = checkString(label);
    this.port = 0;
  }

  WifiAdHocDevice.unit(String name, String mac, int port) : super(
    name: name, mac: mac, type: Service.WIFI
  ) {
    this.port = port;
  }

  WifiAdHocDevice.fromWifiP2pDevice(WifiP2pDevice device) : super(
    name: device.name, mac: device.mac, type: Service.WIFI
  ) {
    this.address = '';
    this.port = 0;
  }

/*------------------------------Override methods------------------------------*/

  @override
  String toString() {
    return 'WifiAdHocDevice' +
              'ipAddress=$address' +
              ', port=$port' +
              ', label=$label' +
              ', name$name' +
              ', mac$mac' +
              ', type$type' +
           '}';
  }
}
