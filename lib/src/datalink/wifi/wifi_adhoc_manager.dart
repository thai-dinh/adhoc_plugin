import 'dart:async';
import 'dart:collection';

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

  bool _verbose;
  bool _isDiscovering;
  bool _isPaused;
  HashMap<String, WifiAdHocDevice> _mapMacDevice;
  StreamSubscription<List<WifiP2pDevice>> _discoverySub;
  FlutterWifiP2p _wifiP2p;

  void Function(String, String) _onWifiReady;

  WifiAdHocManager(this._verbose, this._onWifiReady) {
    _isDiscovering = false;
    _isPaused = false;
    _mapMacDevice = HashMap();
    _wifiP2p = FlutterWifiP2p();
    _wifiP2p.verbose = _verbose;
  }

/*------------------------------Getters & Setters-----------------------------*/

  Future<String> get adapterName => _channel.invokeMethod('getAdapterName');

/*-------------------------------Public methods-------------------------------*/

  Future<void> register(void Function(bool, bool, String) onConnection) async {
    _wifiP2p.wifiP2pConnectionStream.listen((info) {
      onConnection(info.groupFormed, info.isGroupOwner, info.groupOwnerAddress);
    });

    _wifiP2p.thisDeviceChangeStream.listen(
      (wifiP2pDevice) async =>
        _onWifiReady(await _wifiP2p.ownIp, await _wifiP2p.mac)
    );

    await _wifiP2p.register();
  }

  void discovery(void onEvent(DiscoveryEvent event)) async {
    if (_verbose) log(TAG, 'discovery()');

    if (_isDiscovering) 
      return;

    if (_isPaused) {
      _discoverySub.resume();

      Timer(
        Duration(milliseconds: DISCOVERY_TIME),
        () => _stopDiscovery(onEvent)
      );

      return;
    }

    _mapMacDevice.clear();

    _discoverySub = _wifiP2p.discoveryStream.listen(
      (listDevices) {
        listDevices.forEach((device) {
          WifiAdHocDevice wifiAdHocDevice = WifiAdHocDevice(device);
          _mapMacDevice.putIfAbsent(device.mac, () {
            if (_verbose) {
              log(TAG, 
                'Device found -> Name: ${device.name} - Address: ${device.mac}'
              );
            }

            return wifiAdHocDevice;
          });

          onEvent(DiscoveryEvent(Service.DEVICE_DISCOVERED, wifiAdHocDevice));
        });
      },
    );

    _wifiP2p.discovery();
    _isDiscovering = true;
    onEvent(DiscoveryEvent(Service.DISCOVERY_STARTED, null));

    Timer(
      Duration(milliseconds: DISCOVERY_TIME),
      () => _stopDiscovery(onEvent)
    );
  }

  Future<void> unregister() async => await unregister(); 

  Future<void> connect(final String remoteAddress) async {
    if (_verbose) log(TAG, 'connect(): $remoteAddress');

    WifiAdHocDevice device = _mapMacDevice[remoteAddress];
    if (device == null)
      throw DeviceNotFoundException('Discovery is required before connecting');

    await _wifiP2p.connect(remoteAddress);
  }

  void removeGroup() => _wifiP2p.removeGroup();

  Future<bool> resetDeviceName() async {
    return await _channel.invokeMethod('resetDeviceName');
  }

  Future<bool> updateDeviceName(final String name) async {
    return await _channel.invokeMethod('updateDeviceName');
  }

  void onEnableWifi(void Function(bool) onEnable) {
    _wifiP2p.wifiStateStream.listen((state) => onEnable(state));
  }

/*------------------------------Private methods-------------------------------*/

  void _stopDiscovery(void onEvent(DiscoveryEvent event)) {
    if (_verbose) log(TAG, 'Discovery completed');

    _isDiscovering = false;
    _isPaused = true;
    _discoverySub.pause();
    onEvent(DiscoveryEvent(Service.DISCOVERY_END, _mapMacDevice));
  }

/*-------------------------------Static methods-------------------------------*/

  static void setVerbose(bool verbose)
    => _channel.invokeMethod('setVerbose', verbose);

  static Future<bool> isWifiEnabled() async {
    return await _channel.invokeMethod('isWifiEnabled');
  }
}
