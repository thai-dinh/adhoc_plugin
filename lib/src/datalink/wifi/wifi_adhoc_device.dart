import 'package:adhoclibrary/src/datalink/service/adhoc_device.dart';
import 'package:adhoclibrary/src/datalink/service/service.dart';
import 'package:flutter_p2p/gen/protos/protos.pb.dart';


class WifiAdHocDevice extends AdHocDevice {
  WifiP2pDevice _wifiP2pDevice;
  String ipAddress;
  int port;

  WifiAdHocDevice(
    this._wifiP2pDevice, {String ipAddress = '', String label = ''}
  ) : super(
    name: _wifiP2pDevice.deviceName,
    mac: _wifiP2pDevice.deviceAddress,
    type: Service.WIFI
  ) {
    this.ipAddress = ipAddress;
    this.port = 0;
  }

  WifiP2pDevice get wifiP2pDevice => _wifiP2pDevice;

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
