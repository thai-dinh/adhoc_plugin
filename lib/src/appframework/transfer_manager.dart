import 'dart:collection';

import 'config.dart';
import '../datalink/exceptions/device_failure.dart';
import '../datalink/service/adhoc_device.dart';
import '../datalink/service/adhoc_event.dart';
import '../datalink/service/constants.dart';
import '../network/datalinkmanager/datalink_manager.dart';
import '../presentation/presentation_manager.dart';


class TransferManager {
  final bool _verbose;

  late DataLinkManager _datalinkManager;
  late PresentationManager _securityManager;

  TransferManager(this._verbose, {Config? config}) {
    this._securityManager = PresentationManager(_verbose, config == null ? Config() : config);
    this._datalinkManager = _securityManager.datalinkManager;
  }

/*------------------------------Getters & Setters-----------------------------*/

  List<AdHocDevice> get directNeighbors => _securityManager.directNeighbors;

  Stream<AdHocEvent> get eventStream => _securityManager.eventStream;

/*-------------------------------Group methods--------------------------------*/

  void createGroup(int groupId) {
    if (_datalinkManager.checkState() == 0)
      throw DeviceFailureException('No wifi and bluetooth connectivity');

    _securityManager.groupController.createSecureGroup();
  }


  void joinGroup(int groupId) {
    if (_datalinkManager.checkState() == 0)
      throw DeviceFailureException('No wifi and bluetooth connectivity');

    _securityManager.groupController.joinSecureGroup();
  }


  void leaveGroup() {
    if (_datalinkManager.checkState() == 0)
      throw DeviceFailureException('No wifi and bluetooth connectivity');

    _securityManager.groupController.leaveSecureGroup();
  }


  void sendMessageToGroup(Object data) {
    if (_datalinkManager.checkState() == 0)
      throw DeviceFailureException('No wifi and bluetooth connectivity');

    _securityManager.groupController.sendMessageToGroup(data);
  }

/*------------------------------Network methods------------------------------*/

  void sendMessageTo(Object data, String destination) {
    if (_datalinkManager.checkState() == 0)
      throw DeviceFailureException('No wifi and bluetooth connectivity');

    _securityManager.send(data, destination, false);
  }


  void sendEncryptedMessageTo(Object data, String destination) {
    if (_datalinkManager.checkState() == 0)
      throw DeviceFailureException('No wifi and bluetooth connectivity');

    _securityManager.send(data, destination, true);
  }


  Future<bool> broadcast(Object data) async {
    if (_datalinkManager.checkState() == 0)
      throw DeviceFailureException('No wifi and bluetooth connectivity');

    return await _securityManager.broadcast(data, false);
  }


  Future<bool> encryptedBroadcast(Object data) async {
    if (_datalinkManager.checkState() == 0)
      throw DeviceFailureException('No wifi and bluetooth connectivity');

    return await _securityManager.broadcast(data, true);
  }


  Future<bool> broadcastExcept(Object data, AdHocDevice excluded) async {
    if (_datalinkManager.checkState() == 0)
      throw DeviceFailureException('No wifi and bluetooth connectivity');

    return await _securityManager.broadcastExcept(data, excluded.label!, false);
  }


  Future<bool> encryptedBroadcastExcept(Object data, AdHocDevice excluded) async {
    if (_datalinkManager.checkState() == 0)
      throw DeviceFailureException('No wifi and bluetooth connectivity');

    return await _securityManager.broadcastExcept(data, excluded.label!, true);
  }

/*------------------------------DataLink methods-----------------------------*/

  void discovery() => _datalinkManager.discovery();


  Future<void> connect(AdHocDevice device, [int? attempts]) async {        
    if (_datalinkManager.checkState() == 0)
      throw DeviceFailureException('No wifi and bluetooth connectivity');

    await _datalinkManager.connect(attempts == null ? 1 : attempts, device);
  }


  void stopListening() {
    _datalinkManager.stopListening();
  }


  void disconnect(AdHocDevice device) => _datalinkManager.disconnect(device.label!);


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
