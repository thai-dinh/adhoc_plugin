import 'dart:async';
import 'dart:io';

import 'package:adhoc_plugin/src/datalink/service/adhoc_event.dart';
import 'package:adhoc_plugin/src/datalink/service/constants.dart';
import 'package:adhoc_plugin/src/datalink/wifi/wifi_p2p_device.dart';
import 'package:adhoc_plugin/src/datalink/wifi/wifi_p2p_info.dart';
import 'package:flutter/services.dart';


/// Class managing the communication between the Dart and platform-specific side.
class WifiP2P {
  static const MethodChannel _methodCh = const MethodChannel('ad.hoc.lib/wifi.method.channel');
  static const EventChannel _eventCh = const EventChannel('ad.hoc.lib/wifi.event.channel');

  late StreamController<AdHocEvent> _controller;

  /// Creates a [WifiP2P] object.
  WifiP2P() {
    this._controller = StreamController<AdHocEvent>.broadcast();
    this._initialize();
  }

/*------------------------------Getters & Setters-----------------------------*/

  /// Returns a [Stream] of [AdHocEvent] events related to Wi-Fi.
  Stream<AdHocEvent> get eventStream => _controller.stream;

  /// Returns the MAC address of the node.
  Future<String> get mac async {
    String _mac = await (_methodCh.invokeMethod('getMacAddress'));
    return _mac.toUpperCase();
  }

  /// Returns the IP address of the node.
  Future<String> get ownIp async {
    String ipAddress = '';
    for (NetworkInterface interface in await NetworkInterface.list()) {
      if (interface.name.compareTo('p2p-wlan0-0') == 0)
        ipAddress = interface.addresses.first.address;
    }

    return ipAddress;
  }

  set verbose(bool verbose) => _methodCh.invokeMethod('setVerbose', verbose);

/*-------------------------------Public methods-------------------------------*/

  Future<void> register() async => await _methodCh.invokeMethod('register');

  Future<void> unregister() async => await _methodCh.invokeMethod('unregister');

  Future<void> discovery() => _methodCh.invokeMethod('discovery');

  Future<void> connect(final String remoteAddress) async {
    await _methodCh.invokeMethod('connect', remoteAddress);
  }

  Future<void> removeGroup() async => await _methodCh.invokeMethod('removeGroup');

  void close() {
    _controller.close();
  }

/*------------------------------Private methods-------------------------------*/

  void _initialize() {
    _eventCh.receiveBroadcastStream().listen((event) {
      Map map = event as Map;

      switch (map['type']) {
        case ANDROID_DISCOVERY:
          List<dynamic> list = map['peers'] as List<dynamic>;
          List<WifiP2PDevice> peers = List.empty(growable: true);
          list.forEach((map) => peers.add(WifiP2PDevice.fromMap(map)));
          _controller.add(AdHocEvent(ANDROID_DISCOVERY, peers));
          break;

        case ANDROID_STATE:
          _controller.add(AdHocEvent(ANDROID_STATE, map['state'] as bool));
          break;

        case ANDROID_CONNECTION:
          WifiP2PInfo info = WifiP2PInfo.fromMap(map['info'] as Map);
          print('INFO0: ${info.groupFormed} ${info.groupOwnerAddress} ${info.isGroupOwner}');
          _controller.add(AdHocEvent(ANDROID_CONNECTION, info));
          break;

        case ANDROID_CHANGES:
          WifiP2PDevice thisDevice = 
            WifiP2PDevice(map['name'] as String, map['mac'] as String);

          _controller.add(AdHocEvent(ANDROID_CHANGES, thisDevice));
          break;

        default:
      }
    });
  }
}
