import 'dart:collection';

import 'package:adhoclibrary/adhoclibrary.dart';


class WifiPlugin {
  HashMap<String, AdHocDevice> _discoveredDevices;
  WrapperWifi _wrapper;

  WifiPlugin() {
    Config config = Config();
    config.label = 'WIFI';
    config.serverPort = 4444;
    _wrapper = WrapperWifi(true, config, HashMap());
  }

/*-------------------------------Public methods-------------------------------*/

  void discoveryExample() {
    _wrapper.discovery((event) {
      if (event.type == Service.DEVICE_DISCOVERED) {
        WifiAdHocDevice device = event.payload as WifiAdHocDevice;
        print('Device ${device.name} found');
      } else if (event.type == Service.DISCOVERY_END) {
        HashMap<String, AdHocDevice> discoveredDevices = 
          event.payload as HashMap<String, AdHocDevice>;

          _discoveredDevices = discoveredDevices;
      } else {
        print('Example: Discovery started');
      }
    });
  }

  void connectExample() {
    _discoveredDevices.forEach((key, value) {
      _wrapper.connect(3, value);
    });
  }

  void removeGroupExample() => _wrapper.removeGroup();

  void stopListeningExample() => _wrapper.stopListening();
}
