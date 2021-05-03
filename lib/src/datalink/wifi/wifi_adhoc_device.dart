import 'package:adhoc_plugin/src/datalink/service/adhoc_device.dart';
import 'package:adhoc_plugin/src/datalink/service/constants.dart';
import 'package:adhoc_plugin/src/datalink/utils/identifier.dart';
import 'package:adhoc_plugin/src/datalink/wifi/wifi_p2p_device.dart';


class WifiAdHocDevice extends AdHocDevice {
  int port;

  WifiAdHocDevice(WifiP2pDevice device) : super(
    name: device.name, mac: Identifier(wifi: device.mac), type: WIFI
  ) {
    this.port = 0;
  }

  WifiAdHocDevice.fromWifiP2pDevice(WifiP2pDevice device) : super(
    name: device.name, mac: Identifier(wifi: device.mac), type: WIFI
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
