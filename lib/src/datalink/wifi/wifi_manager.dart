import 'dart:async';
import 'dart:collection';

import 'package:adhoclibrary/src/datalink/exceptions/device_not_found.dart';
import 'package:adhoclibrary/src/datalink/wifi/wifi_adhoc_device.dart';

import 'package:flutter_p2p/flutter_p2p.dart';

class WifiManager {
  static const DISCOVERY_TIME = 10000;

  List<StreamSubscription> _subscriptions = [];
  HashMap<String, WifiAdHocDevice> _peers;
  bool _isConnected;
  bool _isHost;
  String _leaderAddress;

  WifiManager() {
    _peers = HashMap();
    _isConnected = false;
    _isHost = false;
    _leaderAddress = '';
  }

  HashMap<String, WifiAdHocDevice> get peers => _peers;

  Future<bool> _checkPermission() async {
    if (!await FlutterP2p.isLocationPermissionGranted()) {
      await FlutterP2p.requestLocationPermission();
      return false;
    }

    return true;
  }

  Future<void> register() async {
    if (!await _checkPermission())
      return;

    _subscriptions.add(FlutterP2p.wifiEvents.stateChange.listen((change) {
      // Handle wifi state change
    }));

    _subscriptions.add(FlutterP2p.wifiEvents.connectionChange.listen((change) {
      _isConnected = change.networkInfo.isConnected;
      _isHost = change.wifiP2pInfo.isGroupOwner;
      _leaderAddress = change.wifiP2pInfo.groupOwnerAddress;
    }));

    _subscriptions.add(FlutterP2p.wifiEvents.thisDeviceChange.listen((change) {
      // Handle changes of this device
    }));

    _subscriptions.add(FlutterP2p.wifiEvents.peersChange.listen((event) {
      event.devices.forEach((element) {
        print(element.deviceName);
        _peers.putIfAbsent(element.deviceName, () {
          return WifiAdHocDevice(
            element,
            element.deviceName,
            element.deviceAddress
          );
        });
      });
    }));

    _subscriptions.add(FlutterP2p.wifiEvents.discoveryChange.listen((change) {
      // Handle discovery state changes
    }));

    // Register to the native events which are send to the streams above
    FlutterP2p.register();
  }

  void unregister() {
    _subscriptions.forEach((subscription) => subscription.cancel());
    FlutterP2p.unregister();
  }

  void discovery() {
    FlutterP2p.discoverDevices();
    Timer(Duration(milliseconds: DISCOVERY_TIME), _handleTimeout);
  }

  void _handleTimeout() => FlutterP2p.stopDiscoverDevices();

  Future<bool> connect(final String remoteAddress) async {
    // WifiAdHocDevice device = _peers[remoteAddress];
    // if (device == null)
    //   throw DeviceNotFoundException('Discovery is required before connecting');
  
    // return await FlutterP2p.connect(device.wifiP2pDevice);

    _peers.forEach((key, value) async {
      print(value.deviceName);
      var result = await FlutterP2p.connect(value.wifiP2pDevice);
      print(result);
    });

    return true;
  }

  void cancelConnection(final WifiAdHocDevice device) {
    FlutterP2p.cancelConnect(device.wifiP2pDevice);
  }

  void removeGroup() => FlutterP2p.removeGroup();
}
