import 'dart:async';
import 'dart:collection';
import 'dart:core';

import 'package:adhoc_plugin/src/appframework/config.dart';
import 'package:adhoc_plugin/src/datalink/exceptions/device_failure.dart';
import 'package:adhoc_plugin/src/datalink/service/adhoc_device.dart';
import 'package:adhoc_plugin/src/datalink/service/adhoc_event.dart';
import 'package:adhoc_plugin/src/datalink/service/discovery_event.dart';
import 'package:adhoc_plugin/src/network/aodv/aodv_manager.dart';
import 'package:adhoc_plugin/src/network/datalinkmanager/datalink_manager.dart';


class TransferManager {
  bool _verbose;
  AodvManager _aodvManager;
  DataLinkManager _dataLinkManager;

  TransferManager(bool verbose, {Config config}) {
    this._verbose = verbose;
    this._aodvManager = AodvManager(_verbose, (config == null) ? Config() : config..connectionFlooding = true);
    this._dataLinkManager = _aodvManager.dataLinkManager;
    this._dataLinkManager.enableAll((state) { });
  }

/*------------------------------Getters & Setters-----------------------------*/

  HashSet<AdHocDevice> get setRemoteDevices => _dataLinkManager.setRemoteDevices;

  Stream<AdHocEvent> get eventStream => _aodvManager.eventStream;

  Stream<DiscoveryEvent> get discoveryStream => _dataLinkManager.discoveryStream;

/*------------------------------Network methods------------------------------*/

  void sendMessageTo(Object message, AdHocDevice adHocDevice) {
    if (_dataLinkManager.checkState() == 0)
      throw DeviceFailureException('No wifi and bluetooth connectivity');
    _aodvManager.sendMessageTo(message, adHocDevice.label);
  }

  Future<bool> broadcast(Object message) async {
    if (_dataLinkManager.checkState() == 0)
      throw DeviceFailureException('No wifi and bluetooth connectivity');
    return await _dataLinkManager.broadcastObject(message);
  }

  Future<bool> broadcastExcept(Object message, AdHocDevice excludedDevice) async {
    if (_dataLinkManager.checkState() == 0)
      throw DeviceFailureException('No wifi and bluetooth connectivity');
    return await _dataLinkManager.broadcastObjectExcept(message, excludedDevice.label);
  }

/*------------------------------DataLink methods-----------------------------*/

  void discovery() => _dataLinkManager.discovery();

  Future<void> connect(AdHocDevice device) async {        
    if (_dataLinkManager.checkState() == 0)
      throw DeviceFailureException('No wifi and bluetooth connectivity');
    await _dataLinkManager.connect(1, device);
  }

  void disconnect(AdHocDevice device) => _dataLinkManager.disconnect(device.label);

  void disconnectAll() => _dataLinkManager.disconnectAll();
}
