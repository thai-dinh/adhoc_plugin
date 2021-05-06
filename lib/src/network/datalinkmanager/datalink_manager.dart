import 'dart:async';
import 'dart:collection';

import 'package:adhoc_plugin/src/appframework/config.dart';
import 'package:adhoc_plugin/src/datalink/exceptions/device_failure.dart';
import 'package:adhoc_plugin/src/datalink/service/adhoc_device.dart';
import 'package:adhoc_plugin/src/datalink/service/adhoc_event.dart';
import 'package:adhoc_plugin/src/datalink/service/constants.dart';
import 'package:adhoc_plugin/src/datalink/service/discovery_event.dart';
import 'package:adhoc_plugin/src/datalink/utils/msg_adhoc.dart';
import 'package:adhoc_plugin/src/datalink/utils/msg_header.dart';
import 'package:adhoc_plugin/src/network/datalinkmanager/constants.dart';
import 'package:adhoc_plugin/src/network/datalinkmanager/wrapper_ble.dart';
import 'package:adhoc_plugin/src/network/datalinkmanager/wrapper_network.dart';
import 'package:adhoc_plugin/src/network/datalinkmanager/wrapper_wifi.dart';


class DataLinkManager {
  List<WrapperNetwork> _wrappers;
  HashMap<String, AdHocDevice> _mapAddressDevice;
  StreamController<DiscoveryEvent> _discoveryCtrl;
  StreamController<AdHocEvent> _eventCtrl;

  String label;

  DataLinkManager(bool verbose, Config config) {
    this._mapAddressDevice = HashMap();
    this._wrappers = List.filled(NB_WRAPPERS, null);
    this._wrappers[WIFI] = WrapperWifi(verbose, config, _mapAddressDevice);
    this._wrappers[BLE] = WrapperBle(verbose, config, _mapAddressDevice);
    this._discoveryCtrl = StreamController<DiscoveryEvent>.broadcast();
    this._eventCtrl = StreamController<AdHocEvent>.broadcast();
    this._initialize();
    this.checkState();
    this.label = config.label;
  }

/*------------------------------Getters & Setters-----------------------------*/

  List<AdHocDevice> get directNeighbors {
    List<AdHocDevice> neighbors = List.empty(growable: true);

    for (int i = 0; i < NB_WRAPPERS; i++)
      neighbors.addAll(_wrappers[i].directNeighbors);

    return neighbors;
  }

  Stream<AdHocEvent> get eventStream => _eventCtrl.stream;

  Stream<DiscoveryEvent> get discoveryStream => _discoveryCtrl.stream;

/*-------------------------------Public methods-------------------------------*/

  int checkState() {
    int enabled = 0;
    for (WrapperNetwork wrapper in _wrappers)
      if (wrapper.enabled)
        enabled++;

    return enabled;
  }

  void enable(int duration, int type) {
    _wrappers[type].enable(duration);
  }

  void enableAll() {
    for (WrapperNetwork wrapper in _wrappers)
      enable(3600, wrapper.type);
  }

  void disable(int type) {
    if (_wrappers[type].enabled) {
      _wrappers[type].stopListening();
      _wrappers[type].disable();
    }
  }

  void disableAll() {
    for (WrapperNetwork wrapper in _wrappers)
      if (wrapper.enabled)
        disable(wrapper.type);
  }

  void discovery() {
    int enabled = checkState();
    if (enabled == 0)
      throw DeviceFailureException('No wifi and bluetooth connectivity');

    if (enabled == _wrappers.length) {
      _discovery();
    } else {
      for (WrapperNetwork wrapper in _wrappers) {
        if (wrapper.enabled) {
          wrapper.discovery();
        }
      }
    }
  }

  Future<void> connect(int attempts, AdHocDevice device) async {
    switch (device.type) {
      case WIFI:
        await _wrappers[WIFI].connect(attempts, device);
        break;

      case BLE:
        await _wrappers[BLE].connect(attempts, device);
        break;
    }
  }

  void stopListening() {
    for (WrapperNetwork wrapper in _wrappers)
      if (wrapper.enabled)
        wrapper.stopListening();
  }

  void removeGroup() {
    WrapperWifi wrapperWifi = _wrappers[WIFI];
    if (wrapperWifi.enabled) {
      wrapperWifi.removeGroup();
    } else {
      throw DeviceFailureException("Wifi is not enabled");
    }
  }

  bool isWifiGroupOwner() {
    WrapperWifi wrapperWifi = _wrappers[WIFI];
    if (wrapperWifi.enabled) {
      return wrapperWifi.isWifiGroupOwner();
    } else {
      throw DeviceFailureException("Wifi is not enabled");
    }
  }

  void sendMessage(MessageAdHoc message, String address) {
    for (WrapperNetwork wrapper in _wrappers)
      if (wrapper.enabled)
        wrapper.sendMessage(message, address);
  }

  void broadcast(MessageAdHoc message) {
    for (WrapperNetwork wrapper in _wrappers)
      if (wrapper.enabled)
        wrapper.broadcast(message);
  }

  Future<bool> broadcastObject(Object object) async {
    bool sent = false;
    for (WrapperNetwork wrapper in _wrappers) {
      if (wrapper.enabled) {
        Header header = Header(
          messageType: BROADCAST,
          label: label,
          name: await wrapper.getAdapterName(),
          deviceType: wrapper.type,
        );

        if (wrapper.broadcast(MessageAdHoc(header, object)))
          sent = true;
      }
    }

    return sent;
  }

  void broadcastExcept(MessageAdHoc message, String excludedAddress) {
    for (WrapperNetwork wrapper in _wrappers)
      if (wrapper.enabled)
        wrapper.broadcastExcept(message, excludedAddress);
  }

  Future<bool> broadcastObjectExcept(Object object, String excludedAddress) async {
    bool sent = false;
    for (WrapperNetwork wrapper in _wrappers) {
      if (wrapper.enabled) {
        Header header = Header(
          messageType: BROADCAST,
          label: label,
          name: await wrapper.getAdapterName(),
          deviceType: wrapper.type,
        );

        if (wrapper.broadcastExcept(MessageAdHoc(header, object), excludedAddress))
          sent = true;
      }
    }

    return sent;
  }

  Future<HashMap<String, AdHocDevice>> getPaired() async {
    if (_wrappers[BLE].enabled)
      return await _wrappers[BLE].getPaired();
    return null;
  }

  bool isDirectNeighbors(String address) {
    for (WrapperNetwork wrapper in _wrappers)
      if (wrapper.enabled && wrapper.isDirectNeighbors(address))
        return true;
    return false;
  }

  List<AdHocDevice> getDirectNeighbors() {
    List<AdHocDevice> devices = List.empty(growable: true);

    for (WrapperNetwork wrapper in _wrappers)
      if (wrapper.enabled)
        devices.addAll(wrapper.directNeighbors);

    return devices;
  }

  bool isEnabled(int type) => _wrappers[type].enabled;

  Future<String> getAdapterName(int type) async {
    if (_wrappers[type].enabled)
      return await _wrappers[type].getAdapterName();
    return null;
  }

  Future<HashMap<int, String>> getActifAdapterNames() async {
    HashMap<int, String> adapterNames = HashMap();
    for (WrapperNetwork wrapper in _wrappers) {
      String name = await getAdapterName(wrapper.type);
      if (name != null)
        adapterNames.putIfAbsent(wrapper.type, () => name);
    }

    return adapterNames;
  }

  Future<bool> updateAdapterName(int type, String newName) async {
    if (_wrappers[type].enabled) {
      return await _wrappers[type].updateDeviceName(newName);
    } else {
      throw DeviceFailureException(
        _typeString(type) + ' adapter is not enabled'
      );
    }
  }

  void resetAdapterName(int type) {
    if (_wrappers[type].enabled) {
      _wrappers[type].resetDeviceName();
    } else {
      throw DeviceFailureException(_typeString(type) + ' adapter is not enabled');
    }
  }

  void disconnectAll() {
    for (WrapperNetwork wrapper in _wrappers)
      if (wrapper.enabled)
        wrapper.disconnectAll();
  }

  void disconnect(String remoteDest) {
    for (WrapperNetwork wrapper in _wrappers)
      if (wrapper.enabled)
        wrapper.disconnect(remoteDest);
  }

/*------------------------------Private methods-------------------------------*/

  void _initialize() {
    _wrappers[BLE].eventStream.listen((event) => _eventCtrl.add(event));
    _wrappers[BLE].discoveryStream.listen((event) => _discoveryCtrl.add(event));
    _wrappers[WIFI].eventStream.listen((event) => _eventCtrl.add(event));
    _wrappers[WIFI].discoveryStream.listen((event) => _discoveryCtrl.add(event));
  }

  void _discovery() {
    for (WrapperNetwork wrapper in _wrappers)
      wrapper.discovery();

    Timer.periodic(Duration(milliseconds: POOLING_DISCOVERY), (Timer timer) {
      bool finished = true;
      for (WrapperNetwork wrapper in _wrappers) {
        if (!wrapper.discoveryCompleted) {
          finished = false;
          break;
        }
      }

      if (finished)
        timer.cancel();
    });

    for (WrapperNetwork wrapper in _wrappers)
      wrapper.discoveryCompleted = false;
  }

  String _typeString(int type) {
    switch (type) {
      case BLE:
        return "Ble";
      case WIFI:
        return "Wifi";

      default:
        return "Unknown";
    }
  }
}
