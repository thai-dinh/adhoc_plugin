import 'dart:async';
import 'dart:collection';

import 'package:adhoclibrary/src/appframework/listener_adapter.dart';
import 'package:adhoclibrary/src/datalink/exceptions/device_not_found.dart';
import 'package:adhoclibrary/src/datalink/service/discovery_event.dart';
import 'package:adhoclibrary/src/datalink/service/service.dart';
import 'package:adhoclibrary/src/datalink/utils/utils.dart';
import 'package:adhoclibrary/src/datalink/wifi/wifi_adhoc_device.dart';
import 'package:flutter/services.dart';
import 'package:flutter_p2p/flutter_p2p.dart';


class WifiAdHocManager {
  static const String TAG = "[WifiAdHocManager]";
  static const String _channelName = 'ad.hoc.lib/plugin.wifi.channel';
  static const MethodChannel _channel = const MethodChannel(_channelName);

  void Function(String) _onWifiReady;
  void Function(DiscoveryEvent event) _onEvent;
  void Function(dynamic error) _onError;

  bool _verbose;
  bool _isConnected;
  bool _isListenerSet;
  ListenerAdapter _listenerAdapter;
  List<StreamSubscription> _subscriptions = [];
  HashMap<String, WifiAdHocDevice> _mapMacDevice;

  WifiAdHocManager(this._verbose, this._onWifiReady) {
    _mapMacDevice = HashMap();
    _isConnected = false;
    _isListenerSet = false;
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

    _subscriptions.add(FlutterP2p.wifiEvents.thisDeviceChange.listen((change) {
      if (_verbose) Utils.log(TAG, 'GroupOwner: ${change.isGroupOwner}');
      _getOwnIpAddress();
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

        _mapMacDevice.putIfAbsent(device.deviceAddress, () => wifiAdHocDevice);

        if (!_mapMacDevice.containsKey(device.deviceAddress)) {
          if (_verbose) {
            Utils.log(TAG, 'Device found: ' +
              'Name: ${device.deviceName} - Address: ${device.deviceAddress}'
            );
          }
        }

        _onEvent(DiscoveryEvent(Service.DEVICE_DISCOVERED, wifiAdHocDevice));
      });
    }, onError: _onError));

    _subscriptions.add(FlutterP2p.wifiEvents.discoveryChange.listen((change) {
      if (change.isDiscovering) {
        if (_verbose) Utils.log(TAG, 'Discovery: ${change.isDiscovering}');
        _onEvent(DiscoveryEvent(Service.DISCOVERY_STARTED, null));
      }
    }, onError: _onError));

    FlutterP2p.register();
  }

  void unregister() {
    if (_verbose) Utils.log(TAG, 'unregister()');

    _subscriptions.forEach((subscription) => subscription.cancel());
    FlutterP2p.unregister();
  }

  void discovery(
    void onEvent(DiscoveryEvent event), void onError(dynamic error),
  ) async {
    if (_verbose) Utils.log(TAG, 'discovery()');

    if (_isConnected) return;

    if (!_isListenerSet) {
      _onEvent = onEvent;
      _onError = onError;

      _isListenerSet = true;
    }

    _mapMacDevice.clear();

    await FlutterP2p.discoverDevices();

    Timer(
      Duration(milliseconds: Utils.DISCOVERY_TIME),
      () => _stopDiscovery(onEvent)
    );
  }

  Future<bool> connect(final String remoteAddress) async {
    if (_verbose) Utils.log(TAG, 'connect(): $remoteAddress');

    WifiAdHocDevice device = _mapMacDevice[remoteAddress];
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

  void _stopDiscovery(void onEvent(DiscoveryEvent event)) {
    if (_verbose) Utils.log(TAG, 'Discovery completed');

    onEvent(DiscoveryEvent(Service.DISCOVERY_END, _mapMacDevice));
  }

  Future<void> _getOwnIpAddress() async {
    String ipAddress = await _channel.invokeMethod('getOwnIpAddress');
    if (ipAddress == null)
      ipAddress = '';
    _onWifiReady(ipAddress);
  }

/*-------------------------------Static methods-------------------------------*/

  static void setVerbose(bool verbose)
    => _channel.invokeMethod('setVerbose', verbose);

  static Future<bool> isWifiEnabled() async {
    return await _channel.invokeMethod('isWifiEnabled');
  }
}
