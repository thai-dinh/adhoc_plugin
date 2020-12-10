import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:adhoclibrary/src/datalink/ble/ble_adhoc_device.dart';
import 'package:adhoclibrary/src/datalink/ble/ble_util.dart';

import 'package:flutter/services.dart';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BleAdHocManager {
  static const String _channelName = 'ad.hoc.lib/plugin.ble.channel';
  static const MethodChannel _channel = const MethodChannel(_channelName);

  FlutterReactiveBle _client;
  HashMap<String, BleAdHocDevice> _discovered;
  StreamSubscription<DiscoveredDevice> _subscription;
  Uuid _serviceUuid;
  Uuid _characteristicUuid;
  int mtu;

  BleAdHocManager() {
    _client = FlutterReactiveBle();
    _discovered = HashMap();
    _serviceUuid = Uuid.parse(ADHOC_SERVICE_UUID);
    _characteristicUuid = Uuid.parse(ADHOC_CHARACTERISTIC_UUID);

    mtu = ADHOC_DEFAULT_MTU;
  }

  Future<String> get deviceName async => await _channel.invokeMethod('getName');

  HashMap<String, BleAdHocDevice> get discoveredDevices => _discovered;

  void startAdvertise() => _channel.invokeMethod('startAdvertise');

  void stopAdvertise() => _channel.invokeMethod('stopAdvertise');

  void startScan() {
    _discovered.clear();

    _subscription = _client.scanForDevices(
      withServices: [_serviceUuid],
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

  void connect(String remoteAddress) {
    _client.connectToDevice(
      id: remoteAddress,
      servicesWithCharacteristicsToDiscover: {},
      connectionTimeout: const Duration(seconds: 5),
    ).listen((state) {
      print('Connection state: ${state.connectionState}');
    }, onError: (error) {
      print(error.toString());
    });
  }

  void writeValue(String remoteAddress, Uint8List values) {
    final characteristic = 
      QualifiedCharacteristic(serviceId: _serviceUuid,
                              characteristicId: _characteristicUuid,
                              deviceId: remoteAddress);
    _client.writeCharacteristicWithResponse(characteristic,
                                            value: values.toList());
  }

  Future<Uint8List> readValue(String remoteAddress) async {
    final characteristic = 
      QualifiedCharacteristic(serviceId: _serviceUuid,
                              characteristicId: _characteristicUuid,
                              deviceId: remoteAddress);    
    final response = await _client.readCharacteristic(characteristic);

    return Uint8List.fromList(response);
  }

  Future<void> requestMtu(BleAdHocDevice device, int mtu) async {  
    mtu = await _client.requestMtu(deviceId: device.macAddress, mtu: mtu);
    device.mtu = mtu;
  }
}
