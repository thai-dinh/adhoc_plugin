import 'package:adhoclibrary/adhoclibrary.dart';

class BleClientExample {
  BleAdHocManager _bleAdHocManager;
  BleServiceManager _bleServiceManager;

  BleClientExample() {
    _bleAdHocManager = BleAdHocManager();
    _bleServiceManager = BleServiceManager(_bleAdHocManager.client);
  }

  void startAdvertiseExample() => _bleAdHocManager.startAdvertise();

  void stopAdvertiseExample() => _bleAdHocManager.stopAdvertise();

  void startScanExample() => _bleAdHocManager.startScan();

  void stopScanExample() {
    _bleAdHocManager.stopScan();
    _bleServiceManager.discovered = _bleAdHocManager.discoveredDevices;
  }

  void connectExample() => _bleServiceManager.connect();

  void sendMessageExample() {
    Header header = Header(0, 'Label', 'Example', 'Address');
    MessageAdHoc message = MessageAdHoc(header, 'Test');

    _bleServiceManager.sendMessage(message);
  }

  void receiveMessageExample() => _bleServiceManager.receiveMessage();
}