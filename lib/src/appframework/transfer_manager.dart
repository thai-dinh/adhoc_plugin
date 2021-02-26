import 'dart:collection';

import 'package:adhoclibrary/src/appframework/config.dart';
import 'package:adhoclibrary/src/datalink/exceptions/device_failure.dart';
import 'package:adhoclibrary/src/datalink/service/adhoc_device.dart';
import 'package:adhoclibrary/src/datalink/service/discovery_event.dart';
import 'package:adhoclibrary/src/datalink/service/service.dart';
import 'package:adhoclibrary/src/network/aodv/aodv_manager.dart';
import 'package:adhoclibrary/src/network/datalinkmanager/datalink_manager.dart';
import 'package:adhoclibrary/src/network/datalinkmanager/adhoc_event.dart';


class TransferManager {
  bool _verbose;
  Config _config;
  AodvManager _aodvManager;
  DataLinkManager _dataLinkManager;

  TransferManager(bool verbose, {Config config}) {
    this._verbose = verbose;
    this._config = config == null ? Config() : config;
  }

  void start() {
    this._aodvManager = AodvManager(_verbose, _config);
    this._dataLinkManager = _aodvManager.dataLinkManager;
  }

/*------------------------------Getters & Setters-----------------------------*/

  String get ownAddress => _config.label;

  Config get config => _config;

  Stream<AdHocEvent> get eventStream => _dataLinkManager.eventStream;

  Stream<DiscoveryEvent> get discoveryStream => _dataLinkManager.discoveryStream;

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

  void connect(int attempts, AdHocDevice adHocDevice) {
    if (_dataLinkManager.checkState() == 0)
      throw DeviceFailureException("No wifi and bluetooth connectivity");
    _dataLinkManager.connect(attempts, adHocDevice);
  }

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

  Future<HashMap<String, AdHocDevice>> getPairedBluetoothDevices() async {
    return _dataLinkManager.getPaired();
  }

  List<AdHocDevice> getDirectNeighbors() {
    return _dataLinkManager.getDirectNeighbors();
  }

  void enableAll(void Function(bool) onEnable) {
    _dataLinkManager.enableAll(onEnable);
  }

  void enableWifi(void Function(bool) onEnable) {
    _dataLinkManager.enable(0, Service.WIFI, onEnable);
  }

  void enableBluetooth(int duration, void Function(bool) onEnable) {
    _dataLinkManager.enable(duration, Service.BLUETOOTHLE, onEnable);
  }

  void disableAll() {
    _dataLinkManager.disableAll();
  }

  void disableWifi() {
    _dataLinkManager.disable(Service.WIFI);
  }

  void disableBluetooth() {
    _dataLinkManager.disable(Service.BLUETOOTHLE);
  }

  bool isWifiEnabled() {
      return _dataLinkManager.isEnabled(Service.WIFI);
  }

  bool isBluetoothEnabled() {
    return _dataLinkManager.isEnabled(Service.BLUETOOTHLE);
  }

  Future<bool> updateBluetoothAdapterName(String name) async {
    return await _dataLinkManager.updateAdapterName(Service.BLUETOOTHLE, name);
  }

  Future<bool> updateWifiAdapterName(String name) async {
    return await _dataLinkManager.updateAdapterName(Service.WIFI, name);
  }

  void resetBluetoothAdapterName() {
    _dataLinkManager.resetAdapterName(Service.BLUETOOTHLE);
  }

  void resetWifiAdapterName() {
    _dataLinkManager.resetAdapterName(Service.WIFI);
  }

  void removeWifiGroup() {
    _dataLinkManager.removeGroup();
  }

  bool isWifiGroupOwner() {
    return _dataLinkManager.isWifiGroupOwner();
  }

  Future<HashMap<int, String>> getActifAdapterNames() async {
    return await _dataLinkManager.getActifAdapterNames();
  }

  Future<String> getWifiAdapterName() async {
    return _dataLinkManager.getAdapterName(Service.WIFI);
  }

  Future<String> getBluetoothAdapterName() async {
    return _dataLinkManager.getAdapterName(Service.BLUETOOTHLE);
  }

  void disconnectAll() {
    _dataLinkManager.disconnectAll();
  }

  void disconnect(AdHocDevice adHocDevice) {
    _dataLinkManager.disconnect(adHocDevice.label);
  }
}

