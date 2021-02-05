import 'dart:async';
import 'dart:collection';

import 'package:adhoclibrary/src/appframework/listener_adapter.dart';
import 'package:adhoclibrary/src/datalink/exceptions/device_not_found.dart';
import 'package:adhoclibrary/src/datalink/exceptions/discovery_failed.dart';
import 'package:adhoclibrary/src/datalink/service/discovery_listener.dart';
import 'package:adhoclibrary/src/datalink/utils/utils.dart';
import 'package:adhoclibrary/src/datalink/wifi/wifi_adhoc_device.dart';
import 'package:flutter/services.dart';
import 'package:flutter_p2p/flutter_p2p.dart';


class WifiManager {
  static const String TAG = "[WifiManager]";
  static const String _channelName = 'ad.hoc.lib/plugin.wifi.channel';
  static const MethodChannel _channel = const MethodChannel(_channelName);

  bool _verbose;
  DiscoveryListener _discoveryListener;
  ListenerAdapter _listenerAdapter;
  List<StreamSubscription> _subscriptions = [];
  HashMap<String, WifiAdHocDevice> _mapMacDevices;
  bool _isConnected;

  WifiManager(this._verbose) {
    _mapMacDevices = HashMap();
    _isConnected = false;
  }

/*------------------------------Getters & Setters-----------------------------*/

  Future<String> get adapterName => _channel.invokeMethod('getAdapterName');

/*-------------------------------Public methods-------------------------------*/

  Future<void> register(void Function(bool, bool, String) onConnection) async {
    if (_verbose) Utils.log(TAG, 'register()');

    if (!await _checkPermission())
      return;

    _subscriptions.add(FlutterP2p.wifiEvents.stateChange.listen((change) {
      if (_listenerAdapter != null && change.isEnabled) {
        _listenerAdapter.onEnableWifi(true);
      } else if (_listenerAdapter != null && !change.isEnabled) {
        _listenerAdapter.onEnableWifi(false);
      }
    }));

    _subscriptions.add(FlutterP2p.wifiEvents.connectionChange.listen((change) {
      onConnection(
        _isConnected = change.networkInfo.isConnected,
        change.wifiP2pInfo.isGroupOwner, 
        change.wifiP2pInfo.groupOwnerAddress
      );
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

    if (_isConnected) return;

    this._discoveryListener = discoveryListener;
    bool result = await FlutterP2p.discoverDevices();
    if (!result)
      discoveryListener.onDiscoveryFailed(DiscoveryFailedException());

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

  Future<bool> updateDeviceName(final String name) async {
    return await _channel.invokeMethod('updateDeviceName');
  }

  void onEnableWifi(ListenerAdapter listenerAdapter) {
    this._listenerAdapter = listenerAdapter;
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
