import 'dart:async';
import 'dart:collection';

import 'package:adhoclibrary/src/datalink/exceptions/device_not_found.dart';
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
  String _leaderAddress;

  WifiManager(this._verbose) {
    _mapMacDevices = HashMap();
    _isConnected = false;
    _isHost = false;
    _leaderAddress = '';
  }

/*------------------------------Getters & Setters-----------------------------*/

  HashMap<String, WifiAdHocDevice> get peers => _mapMacDevices;

/*------------------------------Private methods-------------------------------*/

  void _endDiscovery() {
    _discoveryListener.onDiscoveryCompleted(_mapMacDevices);
  }

/*-------------------------------Public methods-------------------------------*/

  Future<bool> _checkPermission() async {
    if (!await FlutterP2p.isLocationPermissionGranted()) {
      await FlutterP2p.requestLocationPermission();
      return false;
    }

    return true;
  }

  Future<void> register() async {
    if (!await _checkPermission())
      return;

    _subscriptions.add(FlutterP2p.wifiEvents.stateChange.listen((change) {
      // Handle wifi state change
    }));

    _subscriptions.add(FlutterP2p.wifiEvents.connectionChange.listen((change) {
      _isConnected = change.networkInfo.isConnected;
      _isHost = change.wifiP2pInfo.isGroupOwner;
      _leaderAddress = change.wifiP2pInfo.groupOwnerAddress;
    }));

    _subscriptions.add(FlutterP2p.wifiEvents.thisDeviceChange.listen((change) {
      // Handle changes of this device
    }));

    _subscriptions.add(FlutterP2p.wifiEvents.peersChange.listen((event) {
      event.devices.forEach((device) {
        WifiAdHocDevice wifiAdHocDevice = WifiAdHocDevice(
          device, device.deviceName, device.deviceAddress
        );

        _mapMacDevices.putIfAbsent(device.deviceName, () {
          if (_verbose) {
            Utils.log(TAG, 
              'Device found -> DeviceName: ${device.deviceName}' + 
              ' - DeviceHardwareAddress: ${device.deviceAddress}'
            );
          }

          return wifiAdHocDevice;
        });

        _discoveryListener.onDeviceDiscovered(wifiAdHocDevice);
      });
    }));

    _subscriptions.add(FlutterP2p.wifiEvents.discoveryChange.listen((change) {
      // Handle discovery state changes
    }));

    // Register to the native events which are send to the streams above
    FlutterP2p.register();
  }

  void unregister() {
    _subscriptions.forEach((subscription) => subscription.cancel());
    FlutterP2p.unregister();
  }

  void discovery(DiscoveryListener discoveryListener) {
    if (_verbose) Utils.log(TAG, 'discovery()');

    this._discoveryListener = discoveryListener;
    FlutterP2p.discoverDevices();
    Timer(Duration(milliseconds: Utils.DISCOVERY_TIME), _endDiscovery);
  }

  Future<bool> connect(final String remoteAddress) async {
    if (_verbose) Utils.log(TAG, 'connect(): $remoteAddress');

    WifiAdHocDevice device = _mapMacDevices[remoteAddress];
    if (device == null)
      throw DeviceNotFoundException('Discovery is required before connecting');
  
    return await FlutterP2p.connect(device.wifiP2pDevice);
  }

  void cancelConnection(final WifiAdHocDevice device) {
    FlutterP2p.cancelConnect(device.wifiP2pDevice);
  }

  void removeGroup() => FlutterP2p.removeGroup();

  Future<bool> resetDeviceName() async {
    return await _channel.invokeMethod('resetDeviceName');
  }

  Future<bool> updateDeviceName(String name) async {
    return await _channel.invokeMethod('updateDeviceName');
  }

  Future<String> getAdapterName() async {
    return await _channel.invokeMethod('getAdapterName');
  }

/*-------------------------------Static methods-------------------------------*/

  static Future<bool> isWifiEnabled() async {
    return await _channel.invokeMethod('isWifiEnabled');
  }
}
