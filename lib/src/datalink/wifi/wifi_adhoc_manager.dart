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
import 'package:adhoc_plugin/src/datalink/wifi/wifi_p2p_info.dart';
import 'package:flutter/services.dart';


/// Class managing the Wi-Fi discovery and the pairing with other Wi-FI devices.
class WifiAdHocManager extends ServiceManager {
  static const String TAG = '[WifiAdHocManager]';
  static const String _channelName = 'ad.hoc.lib/wifi.method.channel';
  static const MethodChannel _channel = const MethodChannel(_channelName);

  late String _adapterName;
  late WifiP2P _wifiP2P;
  late HashMap<String?, WifiAdHocDevice?> _mapMacDevice;
  // late StreamSubscription<AdHocEvent> _streamSubscription;

  /// Creates a [WifiAdHocManager] object.
  /// 
  /// The debug/verbose mode is set if [verbose] is true.
  WifiAdHocManager(bool verbose) : super(verbose) {
    this._adapterName = '';
    this._wifiP2P = WifiP2P();
    this._wifiP2P.verbose = verbose;
    this._mapMacDevice = HashMap();
  }

/*------------------------------Getters & Setters-----------------------------*/

  /// Returns the name of the Wi-Fi adapter.
  String get adapterName => _adapterName;

/*-------------------------------Public methods-------------------------------*/

  /// Initializes the listening process of platform-side streams.
  @override
  void initialize() async {
    _wifiP2P.eventStream.listen((event) async {
      switch (event.type) {
        case ANDROID_DISCOVERY:
          List<WifiP2PDevice> devices = 
            (event.payload as List<dynamic>).cast<WifiP2PDevice>();

          devices.forEach((device) {
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
          break;

        case ANDROID_STATE:
          final bool state = event.payload as bool;
          if (state)
            // Notify upper layer of the Wi-Fi state
            controller.add(AdHocEvent(WIFI_READY, true));
          break;

        case ANDROID_CONNECTION:
          WifiP2PInfo info = event.payload as WifiP2PInfo;
          print('INFO1: ${info.groupFormed} ${info.groupOwnerAddress} ${info.isGroupOwner}');
          // Notify upper layer of the Wi-Fi connection information received
          controller.add(
            AdHocEvent(
              CONNECTION_INFORMATION, 
              [info.groupFormed, info.isGroupOwner, info.groupOwnerAddress]
            )
          );
          break;

        case ANDROID_CHANGES:
          WifiP2PDevice device = event.payload as WifiP2PDevice;

          // Process the name to be more user-friendly
          if (device.name.contains('[Phone]')) {
            _adapterName = device.name.substring(device.name.indexOf(' ') + 1);
          } else {
            _adapterName = device.name;
          }

          // Notify upper layer of this device Wi-Fi information received
          controller.add(
            AdHocEvent(
              DEVICE_INFO_WIFI, 
              [await _wifiP2P.ownIp, await _wifiP2P.mac]
            ),
          );

          // Update the current name on the platform-specific side
          _channel.invokeMethod('currentName', _adapterName);
          break;

        default:
          break;
      }
    });

    await _wifiP2P.register();
  }

  /// Triggers the discovery of other Wi-Fi Direct devices.
  /// 
  /// The process lasts for [DISCOVERY_TIME] seconds.
  @override
  void discovery() {
    if (verbose) log(TAG, 'discovery()');

    // If a discovery process is ongoing, then return
    if (isDiscovering)
      return;

    isDiscovering = true;

    // Clear the history of discovered devices
    _mapMacDevice.clear();

    // Start the discovery process
    _wifiP2P.discovery();

    // Notify upper layer of the discovery process' start
    controller.add(AdHocEvent(DISCOVERY_START, null));

    // Stop the discovery process after DISCOVERY_TIME
    Timer(Duration(milliseconds: DISCOVERY_TIME), () => _stopDiscovery());
  }

  /// Updates the local adapter name of the device with [name].
  /// 
  /// Returns true if the name is successfully set, otherwise false. In case
  /// of error, a null value is returned.
  @override
  Future<bool?> updateDeviceName(final String name) async {
    return await _channel.invokeMethod('updateDeviceName');
  }

  /// Resets the local adapter name of the device.
  /// 
  /// Returns true if the name is successfully reset, otherwise false. In case
  /// of error, a null value is returned.
  @override
  Future<bool?> resetDeviceName() async {
    return await _channel.invokeMethod('resetDeviceName');
  }

  @override
  void close() {
    super.close();
  }

  Future<void> unregister() async => await unregister();

  Future<void> connect(String? mac) async {
    if (verbose) log(TAG, 'connect(): $mac');

    WifiAdHocDevice? device = _mapMacDevice[mac];
    if (device == null)
      throw DeviceNotFoundException('Discovery is required before connecting');

    await _wifiP2P.connect(mac!);
  }

  void removeGroup() => _wifiP2P.removeGroup();

/*------------------------------Private methods-------------------------------*/

  /// Stops the discovery process.
  void _stopDiscovery() {
    if (verbose) log(TAG, 'Discovery completed');

    isDiscovering = false;
    // Notify upper layer of the discovery process' end
    controller.add(AdHocEvent(DISCOVERY_END, _mapMacDevice));
  }

/*-------------------------------Static methods-------------------------------*/

  static void setVerbose(bool verbose) 
    => _channel.invokeMethod('setVerbose', verbose);

  static Future<bool?> isWifiEnabled() async 
    => await _channel.invokeMethod('isWifiEnabled');
}
