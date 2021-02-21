import 'dart:collection';

import 'package:adhoclibrary/adhoclibrary.dart';


class WifiPlugin {
  HashMap<String, AdHocDevice> _discoveredDevices;
  WrapperWifi _wrapper;

  WifiPlugin() {
    _discoveredDevices = HashMap();
    Config config = Config();
    config.label = 'WIFI';
    config.serverPort = 4444;
    _wrapper = WrapperWifi(true, config, HashMap());
  }

/*------------------------------Getters & Setters-----------------------------*/

  List<AdHocDevice> get discoveredDevices {
    List<AdHocDevice> list = List.empty(growable: true);
    _discoveredDevices.entries.forEach((e) => list.add(e.value));
    return list;
  }

/*-------------------------------Public methods-------------------------------*/

  void discovery() {
    print('WifiPlugin: discovery');
    _wrapper.discovery((event) {
      if (event.type == Service.DISCOVERY_END)
        _discoveredDevices = event.payload;
    });
  }

  void connect(AdHocDevice device) {
    print('WifiPlugin: connect to ${device.mac}');
    _wrapper.connect(3, device);
  }

  void disconnectAll() {
    print('WifiPlugin: disconnectAll');
    _wrapper.disconnectAll();
  }

  void removeGroup() {
    print('WifiPlugin: removeGroup');
    _wrapper.removeGroup();
  }

  void printAdapterName() async {
    print('WifiPlugin: printAdapterName');
    print(await _wrapper.getAdapterName());
  }

  void unregister() {
    print('WifiPlugin: unregister');
    _wrapper.unregister();
  }
}
