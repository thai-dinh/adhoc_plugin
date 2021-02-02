import 'dart:collection';

import 'package:adhoclibrary/src/datalink/service/adhoc_device.dart';


class DiscoveryListener {
  void Function(AdHocDevice device) _onDeviceDiscovered;
  void Function(HashMap<String, AdHocDevice> mapNameDevice) _onDiscoveryCompleted;
  void Function() _onDiscoveryStarted;
  void Function(Exception exception) _onDiscoveryFailed;

  DiscoveryListener({
    void Function(AdHocDevice device) onDeviceDiscovered,
    void Function(HashMap<String, AdHocDevice> mapNameDevice) onDiscoveryCompleted,
    void Function() onDiscoveryStarted,
    void Function(Exception exception) onDiscoveryFailed
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
