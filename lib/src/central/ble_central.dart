import 'dart:async';
import 'dart:collection';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class Central {
  FlutterReactiveBle _client;
  HashMap<String, DiscoveredDevice> _discovered;
  StreamSubscription<DiscoveredDevice> _subscription;

  Central() {
    _client = FlutterReactiveBle();
    _discovered = HashMap();
  }

  void startScan() {
    _discovered.clear();

    _subscription = _client.scanForDevices(
      withServices: [],
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

  /// Currently attempt to connect to closest BLE device
  void connect() {
    String id;
    int rssi = -999;

    // Search for closest device
    _discovered.forEach((key, value) {
      if (value.rssi > rssi) {
        id = value.id;
        rssi = value.rssi;
      }
    });

    // Attempt connection
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

  /// Currently discover services of closest BLE device
  void discoverServices() async {
    String id;
    int rssi = -999;

    _discovered.forEach((key, value) { 
      if (value.rssi > rssi) {
        id = value.id;
        rssi = value.rssi;
      }
    });

    _client.discoverServices(id).then((services) {
      services.forEach((service) {
        print('Service: ' + service.serviceId.toString());
        List<Uuid> characteristics = service.characteristicIds;

        characteristics.forEach((characteristic) {
          print('Characteristic: ' + characteristic.toString());
        });
      });
    });
  }
}
