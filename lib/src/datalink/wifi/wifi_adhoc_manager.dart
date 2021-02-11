import 'dart:async';
import 'dart:collection';

import 'package:adhoclibrary/src/appframework/listener_adapter.dart';
import 'package:adhoclibrary/src/datalink/exceptions/device_not_found.dart';
import 'package:adhoclibrary/src/datalink/service/discovery_event.dart';
import 'package:adhoclibrary/src/datalink/service/service.dart';
import 'package:adhoclibrary/src/datalink/utils/utils.dart';
import 'package:adhoclibrary/src/datalink/wifi/wifi_adhoc_device.dart';
import 'package:flutter/services.dart';
import 'package:flutter_wifi_p2p/flutter_wifi_p2p.dart';


class WifiAdHocManager {
  static const String TAG = "[WifiAdHocManager]";
  static const String _channelName = 'ad.hoc.lib/plugin.wifi.channel';
  static const MethodChannel _channel = const MethodChannel(_channelName);

  void Function(String) _onWifiReady;
  void Function(DiscoveryEvent event) _onEvent;
  void Function(dynamic error) _onError;

  bool _verbose;
  bool _isListenerSet;
  ListenerAdapter _listenerAdapter;
  HashMap<String, WifiAdHocDevice> _mapMacDevice;
  WifiP2PManager _wifiP2PManager;

  WifiAdHocManager(this._verbose, this._onWifiReady) {
    _mapMacDevice = HashMap();
    _isListenerSet = false;
    _wifiP2PManager = WifiP2PManager();
  }

/*------------------------------Getters & Setters-----------------------------*/

  Future<String> get adapterName => _channel.invokeMethod('getAdapterName');

/*-------------------------------Public methods-------------------------------*/

  Future<void> initialize(void Function(bool, bool, String) onConnection) async {
    if (_verbose) Utils.log(TAG, '_initialize()');

    await _wifiP2PManager.initialize();

    _wifiP2PManager.wifiStateStream.listen(
      (state) {
        if (_listenerAdapter != null)
          _listenerAdapter.onEnableWifi(state);
      }
    );

    _wifiP2PManager.wifiP2pConnectionStream.listen(
      (wifiP2pInfo) async {
        onConnection(
          wifiP2pInfo.groupFormed,
          wifiP2pInfo.isGroupOwner, 
          wifiP2pInfo.groupOwnerAddress
        );
      }
    );

    _wifiP2PManager.thisDeviceChangeStream.listen(
      (wifiP2pDevice) async => _onWifiReady(await _wifiP2PManager.getOwnIp())
    );
  }

  void discovery(
    void onEvent(DiscoveryEvent event), void onError(dynamic error),
  ) async {
    if (_verbose) Utils.log(TAG, 'discovery()');

    if (!_isListenerSet) {
      _onEvent = onEvent;
      _onError = onError;

      _isListenerSet = true;
    }

    _mapMacDevice.clear();

    _wifiP2PManager.discoveryStream.listen(
      (device) {
        WifiAdHocDevice wifiAdHocDevice = WifiAdHocDevice(device);
        _mapMacDevice.putIfAbsent(device.mac, () => wifiAdHocDevice);

        if (!_mapMacDevice.containsKey(device.mac)) {
          if (_verbose) {
            Utils.log(TAG, 
              'Device found -> Name: ${device.name} - Address: ${device.mac}'
            );
          }
        }

        _onEvent(DiscoveryEvent(Service.DEVICE_DISCOVERED, wifiAdHocDevice));
      }
    );

    _wifiP2PManager.discovery();

    Timer(
      Duration(milliseconds: Utils.DISCOVERY_TIME),
      () => _stopDiscovery(onEvent)
    );
  }

  Future<void> connect(final String remoteAddress) async {
    if (_verbose) Utils.log(TAG, 'connect(): $remoteAddress');

    WifiAdHocDevice device = _mapMacDevice[remoteAddress];
    if (device == null)
      throw DeviceNotFoundException('Discovery is required before connecting');

    await _wifiP2PManager.connect(remoteAddress);
  }

  void removeGroup() => _wifiP2PManager.removeGroup();

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
