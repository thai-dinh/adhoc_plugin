import 'package:adhoc_plugin/src/datalink/service/adhoc_device.dart';
import 'package:adhoc_plugin/src/datalink/service/constants.dart';
import 'package:adhoc_plugin/src/datalink/utils/identifier.dart';


/// Class representing a remote Wifi-capable device.
class WifiAdHocDevice extends AdHocDevice {
  late int port;

  /// Creates a [WifiAdHocDevice] object.
  /// 
  /// The name of the Wi-Fi device is set to [name] and its MAC addresss to [mac].
  WifiAdHocDevice(String name, String mac) : super(
    label: '', address: '', name: name, mac: Identifier(wifi: mac), type: WIFI
  ) {
    port = 0;
  }

/*------------------------------Override methods------------------------------*/

  @override
  String toString() {
    return 'WifiAdHocDevice{' +
              'ipAddress=$address' +
              ', port=$port' +
              ', label=$label' +
              ', name=$name' +
              ', mac=$mac' +
              ', type=${super.typeAsString()}' +
           '}';
  }
}
