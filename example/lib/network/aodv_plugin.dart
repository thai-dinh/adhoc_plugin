import 'dart:collection';

import 'package:adhoclibrary/adhoclibrary.dart';


class AodvPlugin {
  AodvManager _aodvManager;
  DataLinkManager _dataLinkManager;
  HashMap<String, AdHocDevice> _discoveredDevices;

  AodvPlugin() {
    this._aodvManager = AodvManager(true, Config()..connectionFlooding = true);
    this._dataLinkManager = _aodvManager.dataLinkManager;
    this._discoveredDevices = HashMap();
    this._aodvManager.discoveryStream.listen((DiscoveryEvent event) {
      if (event.type == Service.DISCOVERY_END) {
        _discoveredDevices = event.payload;
      }
    });

    this._aodvManager.eventStream.listen((WrapperEvent event) {
      if (event.type == AbstractWrapper.DEVICE_INFO)
        print(event.type.toString() + ', [' + event.payload + '], [' + event.extra + ']');
    });
  }

/*------------------------------Getters & Setters-----------------------------*/

  List<AdHocDevice> get discoveredDevices {
    List<AdHocDevice> list = List.empty(growable: true);
    _discoveredDevices.entries.forEach((e) => list.add(e.value));
    return list;
  }

/*------------------------------Network methods------------------------------*/

  void sendMessageTo(Object message, AdHocDevice adHocDevice) {
    if (_dataLinkManager.checkState() == 0)
      throw DeviceFailureException("No wifi and bluetooth connectivity");
    _aodvManager.sendMessageTo(message, adHocDevice.label);
  }

  Future<bool> broadcast(Object message) async {
    if (_dataLinkManager.checkState() == 0)
      throw DeviceFailureException("No wifi and bluetooth connectivity");
    return await _dataLinkManager.broadcastObject(message);
  }

  Future<bool> broadcastExcept(Object message, AdHocDevice excludedDevice) async {
    if (_dataLinkManager.checkState() == 0)
      throw DeviceFailureException("No wifi and bluetooth connectivity");
    return await _dataLinkManager.broadcastObjectExcept(message, excludedDevice.label);
  }

/*------------------------------DataLink methods-----------------------------*/

  void connectOnce(AdHocDevice adHocDevice) {
    if (_dataLinkManager.checkState() == 0)
      throw DeviceFailureException("No wifi and bluetooth connectivity");
    _dataLinkManager.connect(1, adHocDevice);
  }

  void stopListening() {
    _dataLinkManager.stopListening();
  }

  void discovery() {
    _dataLinkManager.discovery();
  }

  List<AdHocDevice> getDirectNeighbors() {
    return _dataLinkManager.getDirectNeighbors();
  }

  void enableBluetooth() {
    _dataLinkManager.enable(3599, Service.BLUETOOTHLE, (enable) { });
  }

  void removeWifiGroup() {
    _dataLinkManager.removeGroup();
  }

  void disconnectAll() {
    _dataLinkManager.disconnectAll();
  }
}
