import 'dart:collection';

import 'package:adhoclibrary/adhoclibrary.dart';

class BlePlugin {
  HashMap<String, AdHocDevice> _discoveredDevices;
  WrapperBluetoothLE _wrapper;

  BlePlugin() {
    Config config = Config();
    config.label = 'test';
    _wrapper = WrapperBluetoothLE(true, config, HashMap());
  }

  void enableExample() => _wrapper.enable(3600);

  void discoveryExample() {
    DiscoveryListener listener = DiscoveryListener(
      onDeviceDiscovered: (AdHocDevice device) => print('Device ${device.deviceName} found'),
      onDiscoveryCompleted: (HashMap<String, AdHocDevice> map) => _discoveredDevices = map,
      onDiscoveryFailed: (Exception e) => throw e,
      onDiscoveryStarted: () => print('Discovery started')
    );

    _wrapper.discovery(listener);
  }

  void connectExample() {
    _discoveredDevices.forEach((key, value) {
      _wrapper.connect(3, value);
    });
  }
}
