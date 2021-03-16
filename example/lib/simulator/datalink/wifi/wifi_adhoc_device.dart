import 'package:adhoclibrary/adhoclibrary.dart';


class WifiAdHocDevice extends AdHocDevice {
  int port;

  WifiAdHocDevice(
    WifiP2pDevice device, {String ipAddress = '', String label = ''}
  ) : super(
    name: device.name, mac: Identifier(wifi: device.mac), type: Service.WIFI
  ) {
    this.address = checkString(ipAddress);
    this.label = checkString(label);
    this.port = 0;
  }

  WifiAdHocDevice.unit(String name, String mac, int port, String address) : super(
    name: name, mac: Identifier(wifi: mac), type: Service.WIFI
  ) {
    this.address = checkString(address);
    this.port = port;
  }

  WifiAdHocDevice.fromWifiP2pDevice(WifiP2pDevice device) : super(
    name: device.name, mac: Identifier(wifi: device.mac), type: Service.WIFI
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
