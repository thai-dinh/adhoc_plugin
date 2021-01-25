import 'dart:collection';

import 'package:adhoclibrary/adhoclibrary.dart';

class WifiClientExample {
  HashMap<String, WifiAdHocDevice> _peers;
  WifiManager _wifiManager;
  WifiServiceClient _host;
  WifiServiceClient _client;

  WifiClientExample() {
    _wifiManager = WifiManager();
  }

  void registerExample() => _wifiManager.register();

  void startDiscoveryExample() => _wifiManager.startDiscovery();

  void stopDiscoveryExample() {
    _wifiManager.stopDiscovery();
    _peers = _wifiManager.peers;
  }

  void connectExample() => _peers.forEach((key, value) {
    print(value.deviceName);
    if (value.deviceName == '[Phone] Galaxy S5') {
      _client = WifiServiceClient(value, 4444, 3, 5)
        ..connect();
    }
  });

  void hostExample() {
    _host = WifiServiceClient.host(4444, 3, 5)
      ..openHostPort();
  }

  void clientExample() {
    _client.openClientPort();
  }

  void sendMessageExample() {
    Header header = Header(0, 'Label', 'Example', 'Address');
    MessageAdHoc message = MessageAdHoc(header, 'Test');

    _host.sendMessage(message);
  }

  void receiveMessageExample() => print(_client.receiveMessage().toString());
}
