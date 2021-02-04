import 'package:flutter/foundation.dart';

class ListenerAdapter {
  void Function(bool) _onEnableBluetooth;
  void Function(bool) _onEnableWifi;

  ListenerAdapter({
    @required void Function(bool) onEnableBluetooth,
    @required void Function(bool) onEnableWifi
  }) {
    this._onEnableBluetooth = onEnableBluetooth;
    this._onEnableWifi = onEnableWifi;
  }

  void onEnableBluetooth(bool success) {
    _onEnableBluetooth(success);
  }

  void onEnableWifi(bool success) {
    _onEnableWifi(success);
  }
}
