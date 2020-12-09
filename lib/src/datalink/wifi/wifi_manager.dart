import 'dart:async';
import 'dart:collection';

import 'package:flutter_p2p/flutter_p2p.dart';
import 'package:flutter_p2p/gen/protos/protos.pb.dart';

class WifiManager {
  HashMap _peers;
  List<StreamSubscription> _subscriptions = [];

  bool _isConnected = false;
  bool _isHost = false;
  String _leaderAddress = '';

  WifiManager() {
    _peers = HashMap<String, WifiP2pDevice>();
  }

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
      // Handle changes of the connection
      _isConnected = change.networkInfo.isConnected;
      _isHost = change.wifiP2pInfo.isGroupOwner;
      _leaderAddress = change.wifiP2pInfo.groupOwnerAddress;
    }));

    _subscriptions.add(FlutterP2p.wifiEvents.thisDeviceChange.listen((change) {
      // Handle changes of this device
    }));

    _subscriptions.add(FlutterP2p.wifiEvents.peersChange.listen((change) {
      // Handle discovered peers

      change.devices.forEach((element) {
        print(element.deviceName);
        _peers.putIfAbsent(element.deviceName, () => element);
      });
    }));

    _subscriptions.add(FlutterP2p.wifiEvents.discoveryChange.listen((change) {
      // Handle discovery state changes
    }));

    // Register to the native events which are send to the streams above
    FlutterP2p.register();
  }

  void unregister() {
    _subscriptions.forEach((subscription) => subscription.cancel()); // Cancel subscriptions
    FlutterP2p.unregister(); // Unregister from native events
  }

  void discover() {
    FlutterP2p.discoverDevices();
  }

  Future<bool> connect() async {
    WifiP2pDevice device;

    _peers.forEach((key, value) {
      device = value;
    });

    print(device.deviceAddress);

    return await FlutterP2p.connect(device);
  }
}
