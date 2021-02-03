import 'dart:async';
import 'dart:collection';

import 'package:adhoclibrary/src/datalink/exceptions/device_not_found.dart';
import 'package:adhoclibrary/src/datalink/exceptions/discovery_failed.dart';
import 'package:adhoclibrary/src/datalink/service/discovery_listener.dart';
import 'package:adhoclibrary/src/datalink/utils/utils.dart';
import 'package:adhoclibrary/src/datalink/wifi/wifi_adhoc_device.dart';
import 'package:flutter/services.dart';
import 'package:flutter_p2p/flutter_p2p.dart';


class WifiManager {
  static const String TAG = "[FlutterAdHoc][WifiManager]";
  static const String _channelName = 'ad.hoc.lib/plugin.wifi.channel';
  static const MethodChannel _channel = const MethodChannel(_channelName);

  bool _verbose;
  DiscoveryListener _discoveryListener;
  List<StreamSubscription> _subscriptions = [];
  HashMap<String, WifiAdHocDevice> _mapMacDevices;
  bool _isConnected;
  bool _isHost;
  String _groupOwnerAddress;

  WifiManager(this._verbose) {
    _mapMacDevices = HashMap();
    _isConnected = false;
    _isHost = false;
    _groupOwnerAddress = '';
  }

/*-------------------------------Public methods-------------------------------*/

  Future<void> register() async {
    if (_verbose) Utils.log(TAG, 'register()');

    if (!await _checkPermission())
      return;

    _subscriptions.add(FlutterP2p.wifiEvents.stateChange.listen((change) {
      // Handle wifi state change
    }));

    _subscriptions.add(FlutterP2p.wifiEvents.connectionChange.listen((change) {
      _isConnected = change.networkInfo.isConnected;
      _isHost = change.wifiP2pInfo.isGroupOwner;
      _groupOwnerAddress = change.wifiP2pInfo.groupOwnerAddress;

      if (_verbose) Utils.log(TAG, _isConnected.toString() + ' ' + _isHost.toString() + ' ' + _groupOwnerAddress);
    }));

    _subscriptions.add(FlutterP2p.wifiEvents.thisDeviceChange.listen((change) {
      // Handle changes of this device
    }));

    _subscriptions.add(FlutterP2p.wifiEvents.peersChange.listen((event) {
      event.devices.forEach((device) {
        WifiAdHocDevice wifiAdHocDevice = WifiAdHocDevice(
          device, device.deviceName, device.deviceAddress
        );

        _mapMacDevices.putIfAbsent(device.deviceAddress, () {
          if (_verbose) {
            Utils.log(TAG, 'Device found: ' +
              'Name: ${device.deviceName} - Address: ${device.deviceAddress}'
            );
          }

          return wifiAdHocDevice;
        });

        _discoveryListener.onDeviceDiscovered(wifiAdHocDevice);
      });
    }));

    _subscriptions.add(FlutterP2p.wifiEvents.discoveryChange.listen((change) {
      if (change.isDiscovering) {
        if (_verbose) Utils.log(TAG, 'Discovery initiated');
        _discoveryListener.onDiscoveryStarted();
      }
    }));

    FlutterP2p.register();
  }

  void unregister() {
    if (_verbose) Utils.log(TAG, 'unregister()');

    _subscriptions.forEach((subscription) => subscription.cancel());
    FlutterP2p.unregister();
  }

  void discovery(final DiscoveryListener discoveryListener) async {
    if (_verbose) Utils.log(TAG, 'discovery()');

    this._discoveryListener = discoveryListener;
    bool result = await FlutterP2p.discoverDevices();
    if (!result)
      discoveryListener.onDiscoveryFailed(DiscoveryFailedException());

    Timer(Duration(milliseconds: Utils.DISCOVERY_TIME), _endDiscovery);
  }

  void connect(final String remoteAddress) async {
    if (_verbose) Utils.log(TAG, 'connect(): $remoteAddress');

    WifiAdHocDevice device = _mapMacDevices[remoteAddress];
    if (device == null)
      throw DeviceNotFoundException('Discovery is required before connecting');
  
    bool result = await FlutterP2p.connect(device.wifiP2pDevice);
    if (!result) {
      if (_verbose) Utils.log(TAG, 'Error during connecting Wifi Direct');
    }
  }

  void cancelConnection(final WifiAdHocDevice device) {
    FlutterP2p.cancelConnect(device.wifiP2pDevice);
  }

  void removeGroup() => FlutterP2p.removeGroup();

  Future<bool> resetDeviceName() async {
    return await _channel.invokeMethod('resetDeviceName');
  }

  Future<bool> updateDeviceName(final String name) async {
    return await _channel.invokeMethod('updateDeviceName');
  }

  Future<String> getAdapterName() async {
    return await _channel.invokeMethod('getAdapterName');
  }

/*------------------------------Private methods-------------------------------*/

  Future<bool> _checkPermission() async {
    if (!await FlutterP2p.isLocationPermissionGranted()) {
      await FlutterP2p.requestLocationPermission();
      return false;
    }

    return true;
  }

  void _endDiscovery() {
    _discoveryListener.onDiscoveryCompleted(_mapMacDevices);
  }

/*-------------------------------Static methods-------------------------------*/

  static Future<bool> isWifiEnabled() async {
    return await _channel.invokeMethod('isWifiEnabled');
  }
}
