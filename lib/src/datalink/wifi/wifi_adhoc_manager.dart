import 'dart:async';
import 'dart:collection';

import 'package:adhoc_plugin/src/datalink/exceptions/device_not_found.dart';
import 'package:adhoc_plugin/src/datalink/service/adhoc_event.dart';
import 'package:adhoc_plugin/src/datalink/service/constants.dart';
import 'package:adhoc_plugin/src/datalink/service/service_manager.dart';
import 'package:adhoc_plugin/src/datalink/utils/utils.dart';
import 'package:adhoc_plugin/src/datalink/wifi/wifi_adhoc_device.dart';
import 'package:adhoc_plugin/src/datalink/wifi/wifi_p2p.dart';
import 'package:adhoc_plugin/src/datalink/wifi/wifi_p2p_device.dart';
import 'package:flutter/services.dart';


class WifiAdHocManager extends ServiceManager {
  static const String TAG = "[WifiAdHocManager]";
  static const String _channelName = 'ad.hoc.lib/plugin.wifi.channel';
  static const MethodChannel _channel = const MethodChannel(_channelName);

  late bool _isPaused;
  late String _adapterName;
  late WifiP2p _wifiP2p;
  late HashMap<String?, WifiAdHocDevice?> _mapMacDevice;
  late StreamSubscription<List<WifiP2pDevice>> _discoverySub;

  void Function(String, String) _onWifiReady;

  WifiAdHocManager(bool verbose, this._onWifiReady) : super(verbose) {
    this._isPaused = false;
    this._adapterName = '';
    this._wifiP2p = WifiP2p();
    this._wifiP2p.verbose = verbose;
    this._mapMacDevice = HashMap();
  }

/*------------------------------Getters & Setters-----------------------------*/

  String get adapterName => _adapterName;

/*-------------------------------Public methods-------------------------------*/

  void initialize() {
    
  }

  Future<void> register(void Function(bool, bool, String) onConnection) async {
    _wifiP2p.wifiP2pConnectionStream.listen((info) {
      onConnection(
        info.groupFormed!, info.isGroupOwner!, info.groupOwnerAddress!
      );
    });

    _wifiP2p.thisDeviceChangeStream.listen(
      (device) async {
        _adapterName = device.name!.substring(device.name!.indexOf(' ') + 1);

        print(_adapterName + ' | ' + device.name!);

        _onWifiReady(await _wifiP2p.ownIp, await _wifiP2p.mac);
        _channel.invokeMethod('currentName', _adapterName);
      }
    );

    await _wifiP2p.register();
  }

  void discovery() {
    if (verbose) log(TAG, 'discovery()');

    if (isDiscovering) 
      return;

    if (_isPaused) {
      _discoverySub.resume();
      Timer(Duration(milliseconds: DISCOVERY_TIME), () => _stopDiscovery());
      return;
    }

    _mapMacDevice.clear();

    _discoverySub = _wifiP2p.discoveryStream.listen(
      (listDevices) {
        listDevices.forEach((device) {
          WifiAdHocDevice wifiDevice = WifiAdHocDevice(device);
          _mapMacDevice.putIfAbsent(wifiDevice.mac, () {
            if (verbose) {
              log(TAG, 
                'Device found -> Name: ${device.name} - Address: ${device.mac}'
              );
            }

            return wifiDevice;
          });

          controller.add(AdHocEvent(DEVICE_DISCOVERED, wifiDevice));
        });
      },
    );

    _wifiP2p.discovery();
    isDiscovering = true;
    controller.add(AdHocEvent(DISCOVERY_START, []));

    Timer(Duration(milliseconds: DISCOVERY_TIME), () => _stopDiscovery());
  }

  Future<void> unregister() async => await unregister();

  Future<void> connect(String? mac) async {
    if (verbose) log(TAG, 'connect(): $mac');

    WifiAdHocDevice? device = _mapMacDevice[mac];
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

  void onEnableWifi() {
    _wifiP2p.wifiStateStream.listen((state) {
      if (state) controller.add(AdHocEvent(WIFI_READY, true));
    });
  }

/*------------------------------Private methods-------------------------------*/

  void _stopDiscovery() {
    if (verbose) log(TAG, 'Discovery completed');

    isDiscovering = false;
    _isPaused = true;
    _discoverySub.pause();

    controller.add(AdHocEvent(DISCOVERY_END, _mapMacDevice));
  }

/*-------------------------------Static methods-------------------------------*/

  static void setVerbose(bool verbose) => _channel.invokeMethod('setVerbose', verbose);

  static Future<bool?> isWifiEnabled() async => await _channel.invokeMethod('isWifiEnabled');
}
