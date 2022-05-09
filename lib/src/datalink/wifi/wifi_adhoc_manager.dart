import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:adhoc_plugin/src/datalink/exceptions/device_not_found.dart';
import 'package:adhoc_plugin/src/datalink/service/adhoc_event.dart';
import 'package:adhoc_plugin/src/datalink/service/constants.dart';
import 'package:adhoc_plugin/src/datalink/service/service_manager.dart';
import 'package:adhoc_plugin/src/datalink/utils/utils.dart';
import 'package:adhoc_plugin/src/datalink/wifi/wifi_adhoc_device.dart';
import 'package:flutter/services.dart';

/// Class managing the Wi-Fi discovery and the pairing process with other
/// Wi-Fi devices.
class WifiAdHocManager extends ServiceManager {
  static const String TAG = '[WifiAdHocManager]';

  static const String _methodName = 'ad.hoc.lib/wifi.method.channel';
  static const String _eventName = 'ad.hoc.lib/wifi.event.channel';
  static const MethodChannel _methodCh = MethodChannel(_methodName);
  static const EventChannel _eventCh = EventChannel(_eventName);

  late String _adapterName;
  late HashMap<String?, WifiAdHocDevice?> _mapMacDevice;

  /// Creates a [WifiAdHocManager] object.
  ///
  /// The debug/verbose mode is set if [verbose] is true.
  WifiAdHocManager(bool verbose) : super(verbose) {
    _methodCh.invokeMethod('setVerbose', verbose);
    _adapterName = '';
    _mapMacDevice = HashMap();
  }

/*------------------------------Getters & Setters-----------------------------*/

  /// Sets the current name of the Wi-Fi adapter to [name].
  set currentName(String name) => _methodCh.invokeMethod('currentName', name);

  /// Returns the name of the Wi-Fi adapter.
  String get adapterName => _adapterName;

  /// Returns the MAC address in upper case of the Wi-Fi adapter.
  Future<String> get mac async {
    var _mac = await _methodCh.invokeMethod('getMacAddress') as String;
    return _mac.toUpperCase();
  }

  /// Returns the Wi-Fi Direct IP address of the device.
  Future<String> get ownIp async {
    var ipAddress = '';

    // TODO: Does not find the p2p interface
    for (var interface in await NetworkInterface.list()) {
      if (interface.name.compareTo('p2p-wlan0-0') == 0) {
        ipAddress = interface.addresses.first.address;
      }
    }

    return ipAddress;
  }

/*------------------------------Override methods------------------------------*/

  /// Closes the stream controller and unregister the broadcast receiver for
  /// Wi-Fi events.
  @override
  void release() {
    super.release();
    _methodCh.invokeMethod('unregister');
  }

  /// Initializes the listening process of platform-side streams.
  @override
  void initialize() async {
    _eventCh.receiveBroadcastStream().listen((event) async {
      var map = event as Map;

      switch (map['type']) {
        case ANDROID_DISCOVERY: // Discovery process
          var list = map['peers'] as List<dynamic>;
          var peers = List<_WifiP2PDevice>.empty(growable: true);
          for (var map in list) {
            peers.add(_WifiP2PDevice.fromMap(map as Map<dynamic, dynamic>));
          }

          for (var device in peers) {
            // Get a WifiAdHocDevice object from device
            var wifiDevice = WifiAdHocDevice(device.name, device.mac);
            // Add the discovered device to the HashMap
            _mapMacDevice.putIfAbsent(wifiDevice.mac.wifi, () {
              if (verbose) {
                log(TAG,
                    'Device found: Name=(${device.name}) - Address=(${device.mac})');
              }

              return wifiDevice;
            });

            // Notify upper layer of a device discovered
            controller.add(AdHocEvent(DEVICE_DISCOVERED, wifiDevice));
          }
          break;

        case ANDROID_STATE: // Status of the Wi-Fi (enabled/disabled)
          // Notify upper layer of the Wi-Fi state
          controller.add(AdHocEvent(WIFI_READY, map['state'] as bool));
          break;

        case ANDROID_CONNECTION: // Information about the group after connection
          var info = _WifiP2PInfo.fromMap(map['info'] as Map);

          // Notify upper layer of the Wi-Fi connection information received
          controller.add(AdHocEvent(CONNECTION_INFORMATION,
              [info.groupFormed, info.isGroupOwner, info.groupOwnerAddress]));
          break;

        case ANDROID_CHANGES:
          var name = map['name'] as String;

          // Process the name to be more user-friendly
          if (name.contains('[Phone]')) {
            _adapterName = name.substring(name.indexOf(' ') + 1);
          } else {
            _adapterName = name;
          }

          // Notify upper layer of this device Wi-Fi information received
          controller
              .add(AdHocEvent(DEVICE_INFO_WIFI, [await ownIp, await mac]));

          // Update the current name on the platform-specific side
          currentName = _adapterName;
          break;

        default:
      }
    });

    await _methodCh.invokeMethod('register');
  }

  /// Triggers the discovery process of other Wi-Fi Direct devices.
  ///
  /// The process lasts for [DISCOVERY_TIME] seconds.
  @override
  void discovery() {
    if (verbose) log(TAG, 'discovery()');

    // If a discovery process is ongoing, then return
    if (isDiscovering) {
      return;
    }

    isDiscovering = true;

    // Clear the history of discovered devices
    _mapMacDevice.clear();

    // Start the discovery process
    _methodCh.invokeMethod('discovery');

    // Notify upper layer of the discovery process' start
    controller.add(AdHocEvent(DISCOVERY_START, []));

    // Stop the discovery process after DISCOVERY_TIME
    Timer(Duration(milliseconds: DISCOVERY_TIME), () {
      if (verbose) log(TAG, 'Discovery completed');

      isDiscovering = false;
      // Notify upper layer of the discovery process end
      controller.add(AdHocEvent(DISCOVERY_END, _mapMacDevice));
    });
  }

  /// Updates the local adapter name of the device with [name].
  @override
  Future<bool> updateDeviceName(final String name) async {
    return await _methodCh.invokeMethod('updateDeviceName') as bool;
  }

  /// Resets the local adapter name of the device.
  @override
  Future<bool> resetDeviceName() async {
    return await _methodCh.invokeMethod('resetDeviceName') as bool;
  }

/*-------------------------------Public methods-------------------------------*/

  /// Performs a connection with the remote device of MAC address [mac].
  Future<void> connect(String mac) async {
    if (verbose) log(TAG, 'connect(): $mac');

    var device = _mapMacDevice[mac];
    if (device == null) {
      throw DeviceNotFoundException('Discovery is required before connecting');
    }

    await _methodCh.invokeMethod('connect', mac);
  }

/*-------------------------------Static methods-------------------------------*/

  /// Checks whether the Wi-Fi technology is enabled.
  ///
  /// Returns true if it is, otherwise false.
  static Future<bool> isWifiEnabled() async {
    return await _methodCh.invokeMethod('isWifiEnabled') as bool;
  }

  /// Removes the device from a Wi-Fi Direct group.
  static Future<void> removeGroup() async {
    await _methodCh.invokeMethod('removeGroup');
  }
}

/// Class representing a Wi-Fi P2P devices.
class _WifiP2PDevice {
  late String name;
  late String mac;

  /// Creates a [_WifiP2PDevice] object.
  ///
  /// The device is named after [name] and has the MAC address [mac].
  _WifiP2PDevice(this.name, this.mac);

  /// Creates a [_WifiP2PDevice] object.
  ///
  /// The object is filled with information from [map]. The map should be a map
  /// with the key type as [String] and value type as [dynamic]. The following
  /// key should exits: 'name' and 'mac'.
  _WifiP2PDevice.fromMap(Map map) {
    name = map['name'] as String;
    mac = map['mac'] as String;
  }
}

/// Class representing a Wi-Fi P2P connection information.
class _WifiP2PInfo {
  late String groupOwnerAddress;
  late bool groupFormed;
  late bool isGroupOwner;

  /// Creates a [_WifiP2PInfo] object.
  ///
  /// The object is filled with information from [map]. The map should be a map
  /// with the key type as [String] and value type as [dynamic]. The following
  /// key should exits: 'groupOwnerAddress', 'groupFormed', and 'isGroupOwner'.
  _WifiP2PInfo.fromMap(Map map) {
    groupOwnerAddress = map['groupOwnerAddress'] as String;
    groupFormed = map['groupFormed'] as bool;
    isGroupOwner = map['isGroupOwner'] as bool;
  }
}
