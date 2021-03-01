import 'dart:async';
import 'dart:collection';

import 'package:adhoclibrary/adhoclibrary.dart' hide WrapperWifi, WifiAdHocDevice;
import 'wrapper_wifi.dart';



class DataLinkManager {
  Config _config;
  AbstractWrapper _wrapper;
  HashMap<String, AdHocDevice> _mapAddrDevice;
  StreamController<AdHocEvent> _eventCtrl;

  DataLinkManager(bool verbose, this._config, int index, List<AdHocDevice> devices) {
    this._mapAddrDevice = HashMap();
    this._wrapper = WrapperWifi(verbose, _config, _mapAddrDevice, index, devices);
    this._eventCtrl = StreamController<AdHocEvent>();
    this._initialize();
    this.checkState();
  }

/*------------------------------Getters & Setters-----------------------------*/

  HashSet<AdHocDevice> get setRemoteDevices {
    return HashSet()..addAll(_wrapper.setRemoteDevices);
  }

  Stream<AdHocEvent> get eventStream async* {
    await for (AdHocEvent event in _eventCtrl.stream) {
      yield event;
    }
  }

/*-------------------------------Public methods-------------------------------*/

  int checkState() {
    return (_wrapper.enabled == true) ? 1 : 0;
  }

  void enable(int duration, int type, void Function(bool) onEnable) {
    _wrapper.enable(duration, (bool success) => onEnable(success));
  }

  void enableAll(void Function(bool) onEnable) {
    enable(3600, Service.WIFI, onEnable);
  }

  void disable(int type) {
    if (_wrapper.enabled) {
      _wrapper.stopListening();
      _wrapper.disable();
    }
  }

  void disableAll() {
    if (_wrapper.enabled)
      disable(_wrapper.type);
  }

  void discovery() {
    int enabled = checkState();
    if (enabled == 0)
      throw DeviceFailureException('No wifi and bluetooth connectivity');

    if (enabled == 1) {
      _discovery();
    } else {
      if (_wrapper.enabled)
        _wrapper.discovery();
    }
  }

  void connect(int attempts, AdHocDevice adHocDevice) {
    _wrapper.connect(attempts, adHocDevice);
  }

  void stopListening() {
    if (_wrapper.enabled)
      _wrapper.stopListening();
  }

  void removeGroup() {
    WrapperWifi wrapperWifi = _wrapper;
    if (wrapperWifi.enabled) {
      wrapperWifi.removeGroup();
    } else {
      throw DeviceFailureException("Wifi is not enabled");
    }
  }

  bool isWifiGroupOwner() {
    WrapperWifi wrapperWifi = _wrapper;
    if (wrapperWifi.enabled) {
      return wrapperWifi.isWifiGroupOwner();
    } else {
      throw DeviceFailureException("Wifi is not enabled");
    }
  }

  void sendMessage(MessageAdHoc message, String address) {
    if (_wrapper.enabled)
      _wrapper.sendMessage(message, address);
  }

  void broadcast(MessageAdHoc message) {
    if (_wrapper.enabled)
      _wrapper.broadcast(message);
  }

  Future<bool> broadcastObject(Object object) async {
    bool sent = false;
    if (_wrapper.enabled) {
      Header header = Header(
        messageType: AbstractWrapper.BROADCAST,
        label: _config.label,
        name: await _wrapper.getAdapterName(),
        deviceType: _wrapper.type,
      );

      if (_wrapper.broadcast(MessageAdHoc(header, object)))
        sent = true;
    }

    return sent;
  }

  void broadcastExcept(MessageAdHoc message, String excludedAddress) {
    if (_wrapper.enabled)
      _wrapper.broadcastExcept(message, excludedAddress);
  }

  Future<bool> broadcastObjectExcept(Object object, String excludedAddress) async {
    bool sent = false;
    if (_wrapper.enabled) {
      Header header = Header(
        messageType: AbstractWrapper.BROADCAST,
        label: _config.label,
        name: await _wrapper.getAdapterName(),
        deviceType: _wrapper.type,
      );

      if (_wrapper.broadcastExcept(MessageAdHoc(header, object), excludedAddress))
        sent = true;
    }

    return sent;
  }

  Future<HashMap<String, AdHocDevice>> getPaired() async {
    return null;
  }

  bool isDirectNeighbors(String address) {
    if (_wrapper.enabled && _wrapper.isDirectNeighbors(address))
      return true;
    return false;
  }

  List<AdHocDevice> getDirectNeighbors() {
    List<AdHocDevice> adHocDevices = List.empty(growable: true);

    if (_wrapper.enabled)
      adHocDevices.addAll(_wrapper.directNeighbors);

    return adHocDevices;
  }

  bool isEnabled(int type) => _wrapper.enabled;

  Future<String> getAdapterName(int type) async {
    if (_wrapper.enabled)
      return await _wrapper.getAdapterName();
    return null;
  }

  Future<HashMap<int, String>> getActifAdapterNames() async {
    HashMap<int, String> adapterNames = HashMap();
    String name = await getAdapterName(_wrapper.type);
    if (name != null)
      adapterNames.putIfAbsent(_wrapper.type, () => name);

    return adapterNames;
  }

  Future<bool> updateAdapterName(int type, String newName) async {
    if (_wrapper.enabled) {
      return await _wrapper.updateDeviceName(newName);
    } else {
      throw DeviceFailureException(
        _typeString(type) + ' adapter is not enabled'
      );
    }
  }

  void resetAdapterName(int type) {
    if (_wrapper.enabled) {
      _wrapper.resetDeviceName();
    } else {
      throw DeviceFailureException(_typeString(type) + ' adapter is not enabled');
    }
  }

  void disconnectAll() {
    if (_wrapper.enabled)
      _wrapper.disconnectAll();
  }

  void disconnect(String remoteDest) {
    if (_wrapper.enabled)
      _wrapper.disconnect(remoteDest);
  }

/*------------------------------Private methods-------------------------------*/

  void _initialize() {
    _wrapper.eventStream.listen((event) {
      _eventCtrl.add(event);
    });
  }

  void _discovery() { }

  String _typeString(int type) {
    switch (type) {
      case Service.BLUETOOTHLE:
        return "BluetoothLE";
      case Service.WIFI:
        return "Wifi";

      default:
        return "Unknown";
    }
  }
}
