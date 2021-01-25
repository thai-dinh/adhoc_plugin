import 'dart:collection';

import 'package:adhoclibrary/adhoclibrary.dart';

class BleClientExample {
  BleAdHocManager _bleAdHocManager;
  HashMap<String, BleAdHocDevice> _discovered;
  HashMap<String, BleClient> _bleClients;
  BleServer _bleServer;

  BleClientExample() {
    this._bleAdHocManager = BleAdHocManager(true);
    this._discovered = HashMap<String, BleAdHocDevice>();
    this._bleClients = HashMap<String, BleClient>();
    this._bleServer = BleServer()
      ..listen();
  }

  void startAdvertiseExample() => _bleAdHocManager.startAdvertise();

  void stopAdvertiseExample() => _bleAdHocManager.stopAdvertise();

  void startScanExample() => _bleAdHocManager.startScan();

  void stopScanExample() {
    _bleAdHocManager.stopScan();
    _discovered = _bleAdHocManager.discoveredDevices;
  }

  void connectExample() {
    _discovered.forEach((key, value) {
      _bleClients.putIfAbsent(key, () {
        BleClient bleClient = BleClient(value, 3, 5);
        bleClient.connect();
        bleClient.listen();
        return bleClient;
      });
    });
  }

  void sendMessageExample() {
    Header header = Header(0, 'Label', 'Example', 'Address');
    MessageAdHoc message = MessageAdHoc(header, 'Test');

    _bleClients.forEach((key, value) {
      value.send(message);
    });
  }

  void receiveMessageExample() {
    _bleClients.forEach((key, value) {
      print(value.getMessage().toString());
    });

    print(_bleServer.getMessage().toString());
  }
}