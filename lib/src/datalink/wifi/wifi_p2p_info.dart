class WifiP2PInfo {
  late String groupOwnerAddress;
  late bool groupFormed;
  late bool isGroupOwner;

  WifiP2PInfo();

  WifiP2PInfo.fromMap(Map map) {
    groupOwnerAddress = map['groupOwnerAddress'];
    groupFormed = map['groupFormed'];
    isGroupOwner = map['isGroupOwner'];
  }
}
