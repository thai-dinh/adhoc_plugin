class WifiP2pDevice {
  late String name;
  late String mac;

  WifiP2pDevice();

  WifiP2pDevice.fromMap(Map map) {
    name = map['name'];
    mac = map['mac'];
  }
}
