import 'dart:async';
import 'dart:collection';

import 'package:adhoc_plugin/src/datalink/exceptions/device_not_found.dart';
import 'package:adhoc_plugin/src/datalink/service/constants.dart';
import 'package:adhoc_plugin/src/datalink/service/discovery_event.dart';
import 'package:adhoc_plugin/src/datalink/utils/utils.dart';
import 'package:adhoc_plugin/src/datalink/wifi/wifi_adhoc_device.dart';
import 'package:adhoc_plugin/src/datalink/wifi/wifi_p2p.dart';
import 'package:adhoc_plugin/src/datalink/wifi/wifi_p2p_device.dart';
import 'package:flutter/services.dart';


class WifiAdHocManager {
  static const String TAG = "[WifiAdHocManager]";
  static const String _channelName = 'ad.hoc.lib/plugin.wifi.channel';
  static const MethodChannel _channel = const MethodChannel(_channelName);

  bool _verbose;
  HashMap<String?, WifiAdHocDevice>? _mapMacDevice;
  late bool _isDiscovering;
  late bool _isPaused;
  late StreamController<DiscoveryEvent> _discoveryCtrl;
  late StreamSubscription<List<WifiP2pDevice>> _discoverySub;
  late WifiP2p _wifiP2p;

  void Function(String, String) _onWifiReady;

  WifiAdHocManager(this._verbose, this._onWifiReady) {
    this._isDiscovering = false;
    this._isPaused = false;
    this._mapMacDevice = HashMap();
    this._discoveryCtrl = StreamController<DiscoveryEvent>();
    this._wifiP2p = WifiP2p();
    this._wifiP2p.verbose = _verbose;
  }

/*------------------------------Getters & Setters-----------------------------*/

  Future<String?> get adapterName => _channel.invokeMethod('getAdapterName');

  Stream<DiscoveryEvent> get discoveryStream => _discoveryCtrl.stream;

/*-------------------------------Public methods-------------------------------*/

  Future<void> register(void Function(bool?, bool?, String?) onConnection) async {
    _wifiP2p.wifiP2pConnectionStream.listen((info) {
      onConnection(info.groupFormed, info.isGroupOwner, info.groupOwnerAddress);
    });

    _wifiP2p.thisDeviceChangeStream.listen(
      (wifiP2pDevice) async {
        _onWifiReady(await _wifiP2p.ownIp, await _wifiP2p.mac);
        _channel.invokeMethod(
          'currentName', 
          wifiP2pDevice.name!.substring(wifiP2pDevice.name!.indexOf(' ')+1)
        );
      }
    );

    await _wifiP2p.register();
  }

  void discovery() async {
    if (_verbose) log(TAG, 'discovery()');

    if (_isDiscovering) 
      return;

    if (_isPaused) {
      _discoverySub.resume();

      Timer(
        Duration(milliseconds: DISCOVERY_TIME),
        () => _stopDiscovery()
      );

      return;
    }

    _mapMacDevice!.clear();

    _discoverySub = _wifiP2p.discoveryStream.listen(
      (listDevices) {
        listDevices.forEach((device) {
          WifiAdHocDevice wifiDevice = WifiAdHocDevice(device);
          _mapMacDevice!.putIfAbsent(wifiDevice.mac, () {
            if (_verbose) {
              log(TAG, 
                'Device found -> Name: ${device.name} - Address: ${device.mac}'
              );
            }

            return wifiDevice;
          });

          _discoveryCtrl.add(DiscoveryEvent(DEVICE_DISCOVERED, wifiDevice));
        });
      },
    );

    _wifiP2p.discovery();
    _isDiscovering = true;
    _discoveryCtrl.add(DiscoveryEvent(DISCOVERY_START, null));

    Timer(
      Duration(milliseconds: DISCOVERY_TIME),
      () => _stopDiscovery()
    );
  }

  Future<void> unregister() async => await unregister(); 

  Future<void> connect(String? mac) async {
    if (_verbose) log(TAG, 'connect(): $mac');

    WifiAdHocDevice? device = _mapMacDevice![mac];
    if (device == null)
      throw DeviceNotFoundException('Discovery is required before connecting');

    await _wifiP2p.connect(mac);
  }

  void removeGroup() => _wifiP2p.removeGroup();

  Future<bool?> resetDeviceName() async {
    return await _channel.invokeMethod('resetDeviceName');
  }

  Future<bool?> updateDeviceName(final String name) async {
    return await _channel.invokeMethod('updateDeviceName');
  }

  void onEnableWifi() { // TODO stream
    _wifiP2p.wifiStateStream.listen((state) { });
  }

/*------------------------------Private methods-------------------------------*/

  void _stopDiscovery() {
    if (_verbose) log(TAG, 'Discovery completed');

    _isDiscovering = false;
    _isPaused = true;
    _discoverySub.pause();
    _discoveryCtrl.add(DiscoveryEvent(DISCOVERY_END, _mapMacDevice));
  }

/*-------------------------------Static methods-------------------------------*/

  static void setVerbose(bool verbose)
    => _channel.invokeMethod('setVerbose', verbose);

  static Future<bool?> isWifiEnabled() async {
    return await _channel.invokeMethod('isWifiEnabled');
  }
}
