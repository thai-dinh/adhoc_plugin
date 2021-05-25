import '../service/adhoc_device.dart';
import '../service/constants.dart';


/// Class representing a remote Wifi-capable device.
class WifiAdHocDevice extends AdHocDevice {
  late int port;

  /// Creates a [WifiAdHocDevice] object.
  /// 
  /// The instance is filled with information given by [device].
  WifiAdHocDevice(String name, String mac) : super(
    label: '', address: '', name: name, mac: mac, type: WIFI
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
