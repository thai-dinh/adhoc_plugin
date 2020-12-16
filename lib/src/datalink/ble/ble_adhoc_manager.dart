import 'dart:async';
import 'dart:collection';

import 'package:adhoclibrary/src/datalink/ble/ble_adhoc_device.dart';
import 'package:adhoclibrary/src/datalink/ble/ble_util.dart';

import 'package:flutter/services.dart';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BleAdHocManager {
  static const String _mChannelName = 'ad.hoc.lib/plugin.ble.channel';
  static const MethodChannel _mChannel = const MethodChannel(_mChannelName);

  FlutterReactiveBle _client;
  HashMap<String, BleAdHocDevice> _discovered;
  StreamSubscription<DiscoveredDevice> _subscription;
  Uuid serviceUuid;
  Uuid characteristicUuid;

  BleAdHocManager() {
    this._client = FlutterReactiveBle();
    this._discovered = HashMap();
    this.serviceUuid = Uuid.parse(ADHOC_SERVICE_UUID);
    this.characteristicUuid = Uuid.parse(ADHOC_CHARACTERISTIC_UUID);
  }

  FlutterReactiveBle get client => _client;

  Future<String> get deviceName async => await _mChannel.invokeMethod('getName');

  HashMap<String, BleAdHocDevice> get discoveredDevices => _discovered;

  void startAdvertise() async => await _mChannel.invokeMethod('startAdvertise');

  void stopAdvertise() async => await _mChannel.invokeMethod('stopAdvertise');

  void startScan() {
    _discovered.clear();

    _subscription = _client.scanForDevices(
      withServices: [serviceUuid],
      scanMode: ScanMode.lowLatency,
    ).listen((device) { 
      if (!_discovered.containsKey(device.id))
        print('Found ${device.name} (${device.id})');

        _discovered.putIfAbsent(device.id, () => BleAdHocDevice(device));
    }, onError: (error) {
      print(error.toString());
    });
  }

  void stopScan() {
    if (_subscription != null)
      _subscription.cancel();
  }

  Future<void> requestMtu(BleAdHocDevice device, int mtu) async {  
    mtu = await _client.requestMtu(deviceId: device.macAddress, mtu: mtu);
    device.mtu = mtu;
  }
}
