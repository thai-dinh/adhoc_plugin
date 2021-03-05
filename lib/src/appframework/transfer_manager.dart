import 'dart:async';
import 'dart:core';

import 'package:adhoclibrary/src/appframework/config.dart';
import 'package:adhoclibrary/src/datalink/exceptions/device_failure.dart';
import 'package:adhoclibrary/src/datalink/service/adhoc_device.dart';
import 'package:adhoclibrary/src/datalink/service/discovery_event.dart';
import 'package:adhoclibrary/src/network/aodv/aodv_manager.dart';
import 'package:adhoclibrary/src/network/datalinkmanager/datalink_manager.dart';
import 'package:adhoclibrary/src/network/datalinkmanager/adhoc_event.dart';


class TransferManager {
  bool _verbose;
  AodvManager _aodvManager;
  DataLinkManager _dataLinkManager;

  TransferManager(bool verbose, {Config config}) {
    this._verbose = verbose;
    this._aodvManager = AodvManager(_verbose, (config == null) ? Config() : config);
    this._dataLinkManager = _aodvManager.dataLinkManager;
    this._dataLinkManager.enableAll((state) { });
  }

/*------------------------------Getters & Setters-----------------------------*/

  Stream<AdHocEvent> get eventStream => _dataLinkManager.eventStream;

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

  void connect(AdHocDevice device) {        
    if (_dataLinkManager.checkState() == 0)
      throw DeviceFailureException('No wifi and bluetooth connectivity');
    _dataLinkManager.connect(1, device);
  }

  void disconnect(AdHocDevice device) => _dataLinkManager.disconnect(device.label);

  void disconnectAll() => _dataLinkManager.disconnectAll();
}
