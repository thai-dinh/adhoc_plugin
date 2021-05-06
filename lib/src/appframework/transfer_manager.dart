import 'dart:collection';

import 'package:adhoc_plugin/src/appframework/config.dart';
import 'package:adhoc_plugin/src/datalink/exceptions/device_failure.dart';
import 'package:adhoc_plugin/src/datalink/service/adhoc_device.dart';
import 'package:adhoc_plugin/src/datalink/service/adhoc_event.dart';
import 'package:adhoc_plugin/src/datalink/service/constants.dart';
import 'package:adhoc_plugin/src/datalink/service/discovery_event.dart';
import 'package:adhoc_plugin/src/network/datalinkmanager/datalink_manager.dart';
import 'package:adhoc_plugin/src/secure_data/secure_data_manager.dart';


class TransferManager {
  bool _verbose;
  SecureDataManager _secureDataManager;
  DataLinkManager _datalinkManager;

  TransferManager(this._verbose, {Config config}) {
    this._secureDataManager = SecureDataManager(_verbose, config == null ? Config() : config);
    this._datalinkManager = _secureDataManager.datalinkManager;
  }

/*------------------------------Getters & Setters-----------------------------*/

  List<AdHocDevice> get directNeighbors => _secureDataManager.directNeighbors;

  Stream<AdHocEvent> get eventStream => _secureDataManager.eventStream;

  Stream<DiscoveryEvent> get discoveryStream => _secureDataManager.discoveryStream;

/*------------------------------Network methods------------------------------*/

  void sendMessageTo(Object data, String destination) {
    _secureDataManager.send(data, destination, false);
  }

  void sendEncryptedMessageTo(Object data, String destination) {
    _secureDataManager.send(data, destination, true);
  }

  Future<bool> broadcast(Object data) async {
    return await _secureDataManager.broadcast(data, false);
  }

  Future<bool> encryptedBroadcast(Object data) async {
    return await _secureDataManager.broadcast(data, true);
  }

  Future<bool> broadcastExcept(Object data, AdHocDevice excluded) async {
    return await _secureDataManager.broadcastExcept(data, excluded.label, false);
  }

  Future<bool> encryptedBroadcastExcept(Object data, AdHocDevice excluded) async {
    return await _secureDataManager.broadcastExcept(data, excluded.label, true);
  }

/*------------------------------DataLink methods-----------------------------*/

  void discovery() => _datalinkManager.discovery();

  Future<void> connect(AdHocDevice device) async {        
    if (_datalinkManager.checkState() == 0)
      throw DeviceFailureException('No wifi and bluetooth connectivity');
    await _datalinkManager.connect(1, device);
  }

  void close() {
    _datalinkManager.stopListening();
  }

  void disconnect(AdHocDevice device) => _datalinkManager.disconnect(device.label);

  void disconnectAll() => _datalinkManager.disconnectAll();

  void enableBle(int duration) {
    _datalinkManager.enable(duration, BLE);
  }

  void enableWifi(int duration) {
    _datalinkManager.enable(duration, WIFI);
  }

  void enable() {
    _datalinkManager.enableAll();
  }

  Future<String> getAdapterName(int type) async {
    return _datalinkManager.getAdapterName(type);
  }

  Future<HashMap<int, String>> getActifAdapterNames() async {
    return _datalinkManager.getActifAdapterNames();
  }

  Future<bool> updateAdapterName(int type, String newName) async {
    return _datalinkManager.updateAdapterName(type, newName);
  }

  void resetAdapterName(int type) {
    _datalinkManager.resetAdapterName(type);
  }
}
