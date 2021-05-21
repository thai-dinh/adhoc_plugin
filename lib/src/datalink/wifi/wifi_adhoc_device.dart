import 'package:adhoc_plugin/src/datalink/service/adhoc_device.dart';
import 'package:adhoc_plugin/src/datalink/service/constants.dart';
import 'package:adhoc_plugin/src/datalink/wifi/wifi_p2p_device.dart';


/// Class representing a remote Wifi-capable device.
class WifiAdHocDevice extends AdHocDevice {
  late int port;

  /// Creates a [WifiAdHocDevice] object.
  /// 
  /// The instance is filled with information given by [device].
  WifiAdHocDevice(WifiP2PDevice device) : super(
    label: '', address: '', name: device.name, mac: device.mac, type: WIFI
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
              ', type${super.typeAsString()}' +
           '}';
  }
}
