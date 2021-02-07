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

  void enableExample() {
    ListenerAdapter listenerAdapter = ListenerAdapter(
      onEnableBluetooth: (bool success) {

      },

      onEnableWifi: (bool success) {
        
      },
    );

    _wrapper.enable(3600, listenerAdapter);
  }
  void disableExample() => _wrapper.disable();

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
    }, (error) => print(error.toString()));
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
