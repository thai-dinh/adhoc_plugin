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


/// Class managing the Wi-Fi discovery and the pairing with other Wi-FI devices.
class WifiAdHocManager extends ServiceManager {
  static const String TAG = "[WifiAdHocManager]";
  static const String _channelName = 'ad.hoc.lib/plugin.wifi.channel';
  static const MethodChannel _channel = const MethodChannel(_channelName);

  late bool _isPaused;
  late String _adapterName;
  late WifiP2p _wifiP2p;
  late HashMap<String?, WifiAdHocDevice?> _mapMacDevice;
  late StreamSubscription<List<WifiP2pDevice>> _discoverySub;

  /// Creates a [WifiAdHocManager] object.
  /// 
  /// The debug/verbose mode is set if [verbose] is true.
  WifiAdHocManager(bool verbose) : super(verbose) {
    this._isPaused = false;
    this._adapterName = '';
    this._wifiP2p = WifiP2p();
    this._wifiP2p.verbose = verbose;
    this._mapMacDevice = HashMap();
  }

/*------------------------------Getters & Setters-----------------------------*/

  /// Returns the name of the Wi-Fi adapter.
  String get adapterName => _adapterName;

/*-------------------------------Public methods-------------------------------*/

  /// Initializes the listening process of platform-side streams.
  void initialize() async {
    _wifiP2p.wifiP2pConnectionStream.listen((info) {
      controller.add(AdHocEvent(
        CONNECTION_INFORMATION, 
        [info.groupFormed, info.isGroupOwner, info.groupOwnerAddress]
      ));
    });

    _wifiP2p.thisDeviceChangeStream.listen(
      (device) async {
        // Process the name to be more user-friendly
        if (device.name.contains('[Phone]')) {
          _adapterName = device.name.substring(device.name.indexOf(' ') + 1);
        } else {
          _adapterName = device.name;
        }

        // Notify upper layer of Wi-Fi information available
        controller.add(
          AdHocEvent(
            DEVICE_INFO_WIFI, 
            [await _wifiP2p.ownIp, await _wifiP2p.mac]
          ),
        );

        // Update the current name on the platform-specific side
        _channel.invokeMethod('currentName', _adapterName);
      }
    );

    await _wifiP2p.register();
  }

  /// Triggers the discovery of other Wi-Fi Direct devices.
  void discovery() {
    if (verbose) log(TAG, 'discovery()');

    // If a discovery process is ongoing, then return
    if (isDiscovering)
      return;

    if (_isPaused) {
      _discoverySub.resume();
      Timer(Duration(milliseconds: DISCOVERY_TIME), () => _stopDiscovery());
      return;
    }

    // Clear the history of discovered devices
    _mapMacDevice.clear();

    // Listen to the event of the discovery process
    _discoverySub = _wifiP2p.discoveryStream.listen(
      (listDevices) {
        listDevices.forEach((device) {
          // Get a WifiAdHocDevice object from device
          WifiAdHocDevice wifiDevice = WifiAdHocDevice(device);
          // Add the discovered device to the HashMap
          _mapMacDevice.putIfAbsent(wifiDevice.mac, () {
            if (verbose) {
              log(TAG, 
                'Device found -> Name: ${device.name} - Address: ${device.mac}'
              );
            }

            return wifiDevice;
          });

          // Notify upper layer of a device discovered
          controller.add(AdHocEvent(DEVICE_DISCOVERED, wifiDevice));
        });
      },
    );

    // Start the discovery process
    _wifiP2p.discovery();
    isDiscovering = true;
    // Notify upper layer of the discovery process' start
    controller.add(AdHocEvent(DISCOVERY_START, null));
    // Stop the discovery process after DISCOVERY_TIME
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

  /// Updates the local adapter name of the device with [name].
  /// 
  /// Returns true if the name is successfully set, otherwise false. In case
  /// of error, a null value is returned.
  Future<bool?> updateDeviceName(final String name) async {
    return await _channel.invokeMethod('updateDeviceName');
  }

  /// Resets the local adapter name of the device.
  /// 
  /// Returns true if the name is successfully reset, otherwise false. In case
  /// of error, a null value is returned.
  Future<bool?> resetDeviceName() async {
    return await _channel.invokeMethod('resetDeviceName');
  }

  /// Listens to the status of the Wi-Fi adapter.
  void onEnableWifi() {
    _wifiP2p.wifiStateStream.listen((state) {
      // Notify upper layer of Wi-Fi being enabled and ready to be used
      if (state) controller.add(AdHocEvent(WIFI_READY, true));
    });
  }

/*------------------------------Private methods-------------------------------*/

  /// Stops the discovery process.
  void _stopDiscovery() {
    if (verbose) log(TAG, 'Discovery completed');

    isDiscovering = false;
    _isPaused = true;
    // Unsubscribe to the discovery stream
    _discoverySub.pause();
    // Notify upper layer of the discovery process' end
    controller.add(AdHocEvent(DISCOVERY_END, _mapMacDevice));
  }

/*-------------------------------Static methods-------------------------------*/

  static void setVerbose(bool verbose) => _channel.invokeMethod('setVerbose', verbose);

  static Future<bool?> isWifiEnabled() async => await _channel.invokeMethod('isWifiEnabled');
}
