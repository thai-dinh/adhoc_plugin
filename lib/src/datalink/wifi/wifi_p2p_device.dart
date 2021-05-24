/// Class representing a Wi-Fi P2P devices.
class WifiP2PDevice {
  late String name;
  late String mac;

  /// Creates a [WifiP2PDevice] object.
  /// 
  /// The device is named after [name] and has the MAC address [mac].
  WifiP2PDevice(this.name, this.mac);

  /// Creates a [WifiP2PDevice] object.
  /// 
  /// The object is filled with information from [map]. The map should be a map
  /// with the key type as [String] and value type as [dynamic]. The following
  /// key should exits: 'name' and 'mac'.
  WifiP2PDevice.fromMap(Map map) {
    name = map['name'];
    mac = map['mac'];
  }
}
