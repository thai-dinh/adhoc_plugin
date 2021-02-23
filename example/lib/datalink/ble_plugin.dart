import 'dart:async';
import 'dart:collection';

import 'package:adhoclibrary/adhoclibrary.dart';


class BlePlugin {
  HashMap<String, AdHocDevice> _discoveredDevices;
  WrapperBluetoothLE _wrapper;

  BlePlugin() {
    this._discoveredDevices = HashMap();
    this._wrapper = WrapperBluetoothLE(true, Config()..connectionFlooding = true, HashMap());
  }

/*------------------------------Getters & Setters-----------------------------*/

  List<AdHocDevice> get discoveredDevices {
    List<AdHocDevice> list = List.empty(growable: true);
    _discoveredDevices.entries.forEach((e) => list.add(e.value));
    return list;
  }

/*-------------------------------Public methods-------------------------------*/

  void enable() {
    print('BlePlugin: enable');
    _wrapper.enable(3600, (bool isEnable) {});
  }

  void disable() {
    print('BlePlugin: disable');
    _wrapper.disable();
  }

  void discovery() {
    print('BlePlugin: discovery');
    _wrapper.discovery();
    _wrapper.discoveryStream.listen((DiscoveryEvent event) {
      if (event.type == Service.DISCOVERY_END)
        _discoveredDevices = event.payload;
    });
  }

  void connect(AdHocDevice device) {
    print('BlePlugin: connect');
    _wrapper.connect(3, device);
  }

  void stopListening() {
    print('BlePlugin: stopListening');
    _wrapper.stopListening();
  }

  Future<HashMap<String, AdHocDevice>> getPaired() async {
    print('BlePlugin: getPaired');
    return await _wrapper.getPaired();
  }

  void getAdapterName() async {
    print('BlePlugin: getAdapterName');
    print(await _wrapper.getAdapterName());
  }

  void updateDeviceName() async {
    print('BlePlugin: updateDeviceName');
    print(_wrapper.updateDeviceName('NewName'));
  }

  void resetDeviceName() async {
    print('BlePlugin: resetDeviceName');
    print(await _wrapper.resetDeviceName());
  }

  void disconnectAll() {
    print('BlePlugin: disconnectAll');
    _wrapper.disconnectAll();
  }
}
