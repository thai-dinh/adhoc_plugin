import 'dart:async';
import 'dart:collection';

import 'package:adhoclibrary/src/datalink/ble/ble_adhoc_device.dart';
import 'package:adhoclibrary/src/datalink/ble/ble_utils.dart';
import 'package:adhoclibrary/src/datalink/service/discovery_listener.dart';
import 'package:adhoclibrary/src/datalink/utils/utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BleAdHocManager {
  static const String _channelName = 'ad.hoc.lib/plugin.ble.channel';
  static const MethodChannel _channel = const MethodChannel(_channelName);

  bool _isDiscovering;
  DiscoveryListener _discoveryListener;
  FlutterReactiveBle _bleClient;
  HashMap<String, BleAdHocDevice> hashMapBluetoothDevice;
  StreamSubscription<DiscoveredDevice> _subscription;
  Uuid serviceUuid;
  Uuid characteristicUuid;

  BleAdHocManager(bool verbose) {
    this._isDiscovering = false;
    this._bleClient = FlutterReactiveBle();
    this.hashMapBluetoothDevice = HashMap<String, BleAdHocDevice>();
    this.serviceUuid = Uuid.parse(BleUtils.ADHOC_SERVICE_UUID);
    this.characteristicUuid = Uuid.parse(BleUtils.ADHOC_CHARACTERISTIC_UUID);
    _updateVerbose(verbose);
  }

  Future<String> get deviceName async => await _channel.invokeMethod('getName');

  HashMap<String, BleAdHocDevice> get discoveredDevices => hashMapBluetoothDevice;

  void startAdvertise() async => await _channel.invokeMethod('startAdvertise');

  void stopAdvertise() async => await _channel.invokeMethod('stopAdvertise');

  void startScan(DiscoveryListener discoveryListener) {
    if (_isDiscovering)
      this.stopScan();

    this._discoveryListener = discoveryListener;

    hashMapBluetoothDevice.clear();
    discoveryListener.onDiscoveryStarted();

    _subscription = _bleClient.scanForDevices(
      withServices: [serviceUuid],
      scanMode: ScanMode.lowLatency,
    ).listen((device) {
      BleAdHocDevice btDevice = BleAdHocDevice(device);

      if (!hashMapBluetoothDevice.containsKey(device.id)) {
        print('Found ${device.name} (${device.id})');
        discoveryListener.onDeviceDiscovered(btDevice);
      }

      hashMapBluetoothDevice.putIfAbsent(device.id, () => btDevice);
    }, onError: (error) {
      print(error.toString());
    });

    Timer(Duration(milliseconds: Utils.DISCOVERY_TIME), stopScan);
  }

  void stopScan() {
    if (_subscription != null) {
      _subscription.cancel();
      _subscription = null;

      _discoveryListener.onDiscoveryCompleted(hashMapBluetoothDevice);
    }
  }

  void _updateVerbose(bool verbose) => _channel.invokeMethod('verbose', verbose);
}
