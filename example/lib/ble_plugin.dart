import 'dart:collection';

import 'package:adhoclibrary/adhoclibrary.dart';


class BlePlugin {
  HashMap<String, AdHocDevice> _discoveredDevices;
  WrapperBluetoothLE _wrapper;

  BlePlugin() {
    Config config = Config();
    _wrapper = WrapperBluetoothLE(true, config, HashMap());
  }

/*-------------------------------Public methods-------------------------------*/

  void enableExample() {
    _wrapper.enable(3600, (bool isEnable) => print('BLE: $isEnable'));
  }

  void disableExample() => _wrapper.disable();

  void discoveryExample() {
    _wrapper.discovery((event) {
      if (event.type == Service.DEVICE_DISCOVERED) {
        BleAdHocDevice device = event.payload as BleAdHocDevice;
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

  void stopListeningExample() => _wrapper.stopListening();

  void disconnectAllExample() => _wrapper.disconnectAll();
}
