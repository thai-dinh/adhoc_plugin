import 'package:adhoc_plugin/src/datalink/service/adhoc_device.dart';
import 'package:adhoc_plugin/src/datalink/service/constants.dart';
import 'package:adhoc_plugin/src/datalink/wifi/wifi_p2p_device.dart';


/// Class representing a remote Wifi-capable device.
class WifiAdHocDevice extends AdHocDevice {
  int? port;

  /// Initialize a newly created WifiAdHocDevice representing a remote 
  /// Wifi-capable device with information given by discovered [device].
  WifiAdHocDevice(WifiP2pDevice device) : super(
    name: device.name, mac: device.mac, type: WIFI
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
