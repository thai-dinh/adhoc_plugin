import 'dart:async';
import 'dart:collection';

import 'package:adhoclibrary/src/utils.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class Central {
  FlutterReactiveBle _client;
  HashMap<String, DiscoveredDevice> _discovered;
  StreamSubscription<DiscoveredDevice> _subscription;
  Uuid _adhocService;

  Central() {
    _client = FlutterReactiveBle();
    _discovered = HashMap();
    _adhocService = Uuid.parse(ADHOC_SERVICE);
  }

  void startScan() {
    _discovered.clear();

    _subscription = _client.scanForDevices(
      withServices: [_adhocService],
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
    Uuid myService, myCharacteristic;

    _discovered.forEach((key, value) { 
      if (value.rssi > rssi) {
        id = value.id;
        rssi = value.rssi;
      }
    });

    _client.discoverServices(id).then((services) async {
      services.forEach((service) async {
        if (service.serviceId.toString() == '0001') {
          print('MyService' + service.serviceId.toString());
          myService = service.serviceId;
        }

        List<Uuid> characteristics = service.characteristicIds;
        characteristics.forEach((characteristic) async {
          if (characteristic.toString() == '0002') {
            print('MyCharacteristic' + characteristic.toString());
            myCharacteristic = characteristic;
          }
        });

        if (myService != null && myCharacteristic != null) {
          print('WRITE');
          final characteristic = QualifiedCharacteristic(serviceId: myService, characteristicId: myCharacteristic, deviceId: id);
          _client.writeCharacteristicWithResponse(characteristic, value: [42, 24, 22, 44]);

          Future.delayed(Duration(seconds: 5));

          print('READ');
          final characteristicr = QualifiedCharacteristic(serviceId: myService, characteristicId: myCharacteristic, deviceId: id);
          final response = await _client.readCharacteristic(characteristicr);
          response.forEach((element) { print(element); });
          print('Lenght' + response.length.toString());
        }
      });
    });
  }
}
