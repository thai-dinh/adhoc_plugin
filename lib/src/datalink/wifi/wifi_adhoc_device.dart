import 'package:adhoclibrary/src/datalink/service/adhoc_device.dart';
import 'package:adhoclibrary/src/datalink/service/service.dart';
import 'package:adhoclibrary/src/datalink/wifi/wifi_p2p_device.dart';


class WifiAdHocDevice extends AdHocDevice {
  int port;

  WifiAdHocDevice(WifiP2pDevice device) : super(
    name: device.name, mac: device.mac, type: Service.WIFI
  ) {
    this.port = 0;
  }

  WifiAdHocDevice.fromWifiP2pDevice(WifiP2pDevice device) : super(
    name: device.name, mac: device.mac, type: Service.WIFI
  ) {
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
