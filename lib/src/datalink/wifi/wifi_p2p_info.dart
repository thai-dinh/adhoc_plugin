/// Class representing a Wi-Fi P2P connection information.
class WifiP2PInfo {
  late String groupOwnerAddress;
  late bool groupFormed;
  late bool isGroupOwner;

  /// Creates a [WifiP2PInfo] object.
  /// 
  /// The object is filled with information from [map]. The map should be a map
  /// with the key type as [String] and value type as [dynamic]. The following
  /// key should exits: 'groupOwnerAddress', 'groupFormed', and 'isGroupOwner'.
  WifiP2PInfo.fromMap(Map map) {
    groupOwnerAddress = map['groupOwnerAddress'];
    groupFormed = map['groupFormed'];
    isGroupOwner = map['isGroupOwner'];
  }
}
