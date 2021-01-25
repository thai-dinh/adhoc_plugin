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

  void unregisterExample() => _wifiManager.unregister();

  void discoveryExample() => _wifiManager.discovery();

  void connectExample() {
    _peers = _wifiManager.peers;
    _peers.forEach((key, value) async {
      print(value.deviceName);
      await _wifiManager.connect(value.deviceName);
    });
  }

  void cancelConnectionExample() {
    _peers.forEach((key, value) async {
      print(value.deviceName);
      _wifiManager.cancelConnection(value);
    });
  }


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
