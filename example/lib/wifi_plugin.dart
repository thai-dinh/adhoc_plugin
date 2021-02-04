import 'dart:collection';

import 'package:adhoclibrary/adhoclibrary.dart';


class WifiPlugin {
  HashMap<String, AdHocDevice> _discoveredDevices;
  WrapperWifi _wrapper;

  WifiPlugin() {
    Config config = Config();
    config.label = 'WIFI';
    config.serverPort = 4444;
    _wrapper = WrapperWifi(true, config, HashMap(), _initListenerApp());
  }

/*-------------------------------Public methods-------------------------------*/

  void enableExample() => _wrapper.enable(3600);

  void disableExample() => _wrapper.disable();

  void discoveryExample() {
    DiscoveryListener listener = DiscoveryListener(
      onDeviceDiscovered: (AdHocDevice device) {
        print('Device ${device.deviceName} found');
      },

      onDiscoveryCompleted: (HashMap<String, AdHocDevice> map) {
        print('Example: Discovery completed');
        _discoveredDevices = map;
      },

      onDiscoveryFailed: (Exception exception) {
        throw exception;
      },

      onDiscoveryStarted: () {
        print('Example: Discovery started');
      }
    );

    _wrapper.discovery(listener);
  }

  void connectExample() {
    _discoveredDevices.forEach((key, value) {
      _wrapper.connect(3, value);
    });
  }

  void stopListeningExample() => _wrapper.stopListening();

/*------------------------------Private methods-------------------------------*/
  
  ListenerApp _initListenerApp() {
    return ListenerApp(
      onReceivedData: (AdHocDevice adHocDevice, Object pdu) { },

      onForwardData: (AdHocDevice adHocDevice, Object pdu) { },

      onConnection: (AdHocDevice adHocDevice) { },

      onConnectionFailed: (Exception exception) { },

      onConnectionClosed: (AdHocDevice adHocDevice) { },

      onConnectionClosedFailed: (Exception exception) { },

      processMsgException: (Exception exception) { }
    );
  }
}
