class WifiP2pDevice {
  String name;
  String mac;

  WifiP2pDevice();

  WifiP2pDevice.fromMap(Map map) {
    name = map['name'];
    mac = map['mac'];
  }
}
