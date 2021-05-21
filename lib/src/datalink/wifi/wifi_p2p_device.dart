class WifiP2PDevice {
  late String name;
  late String mac;

  WifiP2PDevice(this.name, this.mac);

  WifiP2PDevice.fromMap(Map map) {
    name = map['name'];
    mac = map['mac'];
  }
}
