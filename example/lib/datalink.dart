import 'dart:collection';

import 'package:adhoclibrary/adhoclibrary.dart';


class DataLink {
  HashMap<String, AdHocDevice> _discoveredDevices;
  DataLinkManager _manager;

  DataLink() {
    this._manager = DataLinkManager(true, Config()..connectionFlooding = true);
  }

  List<AdHocDevice> get discoveredDevices {
    List<AdHocDevice> list = List.empty(growable: true);
    _discoveredDevices.entries.forEach((e) => list.add(e.value));
    return list;
  }

  int checkState() => _manager.checkState();

  void enable() => _manager.enable(3600, Service.BLUETOOTHLE, (bool) => print('BLE enabled: $bool'));

  void enableAll() => _manager.enableAll((bool) => print('BLE enabled: $bool'));

  void disable() => _manager.disable(Service.BLUETOOTHLE);

  void disableAll() => _manager.disableAll();

  void discovery() => _manager.discovery((event) {
    if (event.type == Service.DISCOVERY_END)
      _discoveredDevices = event.payload as HashMap<String, AdHocDevice>;
  });

  void connect(AdHocDevice device) => _manager.connect(3, device);

  void stopListening() => _manager.stopListening();

  bool isDirectNeighbors(String address) => _manager.isDirectNeighbors(address);

  void sendMessage(String address) => _manager.sendMessage(MessageAdHoc(Header(messageType: 0), 'Hello'), address);

  void broadcast() => _manager.broadcast(MessageAdHoc(Header(messageType: 0), 'Hello'));

  Future<bool> broadcastObject() async => await _manager.broadcastObject('Hello World!');

  void broadcastExcept(String address) => _manager.broadcastExcept(MessageAdHoc(Header(messageType: 0), 'Hello'), address);

  Future<bool> broadcastObjectExcept(String address) async => await _manager.broadcastObjectExcept('Hello World!', address);

  Future<HashMap<String, AdHocDevice>> getPaired() async => _manager.getPaired();

  List<AdHocDevice> getDirectNeighbors() => _manager.getDirectNeighbors();

  bool isEnabled() => _manager.isEnabled(Service.BLUETOOTHLE);

  Future<String> getAdapterName() async => _manager.getAdapterName(Service.BLUETOOTHLE);

  Future<HashMap<int, String>> getActifAdapterNames() async => _manager.getActifAdapterNames();

  Future<bool> updateAdapterName(String newName) async => _manager.updateAdapterName(Service.BLUETOOTHLE, newName);

  void resetAdapterName() => _manager.resetAdapterName(Service.BLUETOOTHLE);

  void disconnectAll() => _manager.disconnectAll();

  void disconnect(String address) => _manager.disconnect(address);
}
