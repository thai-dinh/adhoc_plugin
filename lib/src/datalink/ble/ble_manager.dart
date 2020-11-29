import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:adhoclibrary/src/datalink/ble/ble_util.dart';

import 'package:flutter/services.dart';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BleManager {
  static const String _channelName = 'ad.hoc.lib/ble.plugin.channel';
  static const MethodChannel _channel = const MethodChannel(_channelName);

  FlutterReactiveBle _client;
  HashMap<String, DiscoveredDevice> _discovered;
  StreamSubscription<DiscoveredDevice> _subscription;
  Uuid _serviceUuid;
  Uuid _characteristicUuid;
  int mtu;

  BleManager() {
    _client = FlutterReactiveBle();
    _discovered = HashMap();
    _serviceUuid = Uuid.parse(ADHOC_SERVICE_UUID);
    _characteristicUuid = Uuid.parse(ADHOC_CHARACTERISTIC_UUID);

    mtu = ADHOC_DEFAULT_MTU;
  }

  Future<String> get deviceName async => await _channel.invokeMethod('getName');

  HashMap<String, DiscoveredDevice> get discoveredDevices => _discovered;

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

        _discovered.putIfAbsent(device.id, () => device);
    }, onError: (error) {
      print(error.toString());
    });
  }

  void stopScan() {
    if (_subscription != null)
      _subscription.cancel();
  }

  void connect() {
    String id;
    int rssi = -999;

    _discovered.forEach((key, value) {
      if (value.rssi > rssi) {
        id = value.id;
        rssi = value.rssi;
      }
    });

    _client.connectToDevice(
      id: id,
      servicesWithCharacteristicsToDiscover: {},
      connectionTimeout: const Duration(seconds: 5),
    ).listen((state) {
      print('Connection state: ${state.connectionState}');
    }, onError: (error) {
      print(error.toString());
    });
  }

  void writeValue(Uint8List values) {
    String id;
    int rssi = -99;

    _discovered.forEach((key, value) { 
      if (value.rssi > rssi) {
        id = value.id;
        rssi = value.rssi;
      }
    });

    final characteristic = 
      QualifiedCharacteristic(serviceId: _serviceUuid,
                              characteristicId: _characteristicUuid,
                              deviceId: id);
    _client.writeCharacteristicWithResponse(characteristic,
                                            value: values.toList());
  }

  Future<Uint8List> readValue() async {
    String id;
    int rssi = -99;

    _discovered.forEach((key, value) { 
      if (value.rssi > rssi) {
        id = value.id;
        rssi = value.rssi;
      }
    });

    final characteristic = 
      QualifiedCharacteristic(serviceId: _serviceUuid,
                              characteristicId: _characteristicUuid,
                              deviceId: id);    
    final response = await _client.readCharacteristic(characteristic);
    response.forEach((element) {
      print(element);
    });

    return Uint8List.fromList(response);
  }

  Future<Map<String, Uint8List>> getValues() async {
    return await _channel.invokeMethod('getValues');
  }
}