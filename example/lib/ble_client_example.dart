import 'dart:collection';

import 'package:adhoclibrary/adhoclibrary.dart';

class BleClientExample {
  BleAdHocManager _bleAdHocManager;
  HashMap<String, BleAdHocDevice> _devices;
  BleServiceClient _bleClient;

  BleClientExample() {
    _bleAdHocManager = BleAdHocManager();
  }

  void startAdvertiseExample() => _bleAdHocManager.startAdvertise();

  void stopAdvertiseExample() => _bleAdHocManager.stopAdvertise();

  void startScanExample() => _bleAdHocManager.startScan();

  void stopScanExample() {
    _bleAdHocManager.stopScan();

    _devices = _bleAdHocManager.discoveredDevices;

    _devices.forEach((key, value) {
      _bleClient = BleServiceClient(_bleAdHocManager.client, value, 3, 5);
    });
  }

  void connectExample() => _bleClient.connect();

  void sendMessageExample() {
    Header header = Header(0, 'Label', 'Example', 'Address');
    MessageAdHoc message = MessageAdHoc(header, 'Test');

    _bleClient.sendMessage(message);
  }

  void receiveMessageExample() {
    MessageAdHoc message = _bleClient.receiveMessage();
    print(message.toString());
  }
}
