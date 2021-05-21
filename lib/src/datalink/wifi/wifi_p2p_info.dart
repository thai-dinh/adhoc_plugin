class WifiP2pInfo {
  late String groupOwnerAddress;
  late bool groupFormed;
  late bool isGroupOwner;

  WifiP2pInfo();

  WifiP2pInfo.fromMap(Map map) {
    groupOwnerAddress = map['groupOwnerAddress'];
    groupFormed = map['groupFormed'];
    isGroupOwner = map['isGroupOwner'];
  }
}
