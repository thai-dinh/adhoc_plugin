import 'dart:collection';

import 'package:adhoclibrary/src/datalink/service/adhoc_device.dart';


class DiscoveryListener {
  void Function(AdHocDevice) _onDeviceDiscovered;
  void Function(HashMap<String, AdHocDevice>) _onDiscoveryCompleted;
  void Function() _onDiscoveryStarted;
  void Function(Exception) _onDiscoveryFailed;

  DiscoveryListener({
    void Function(AdHocDevice) onDeviceDiscovered,
    void Function(HashMap<String, AdHocDevice>) onDiscoveryCompleted,
    void Function() onDiscoveryStarted,
    void Function(Exception) onDiscoveryFailed
  }) {
    this._onDeviceDiscovered = onDeviceDiscovered;
    this._onDiscoveryCompleted = onDiscoveryCompleted;
    this._onDiscoveryStarted = onDiscoveryStarted;
    this._onDiscoveryFailed = onDiscoveryFailed;
  }

  void onDeviceDiscovered(AdHocDevice device) {
    _onDeviceDiscovered(device);
  }

  void onDiscoveryCompleted(HashMap<String, AdHocDevice> mapNameDevice) {
    _onDiscoveryCompleted(mapNameDevice);
  }

  void onDiscoveryStarted() {
    _onDiscoveryStarted();
  }

  void onDiscoveryFailed(Exception exception) {
    _onDiscoveryFailed(exception);
  }
}
