class WifiP2pInfo {
  String? groupOwnerAddress;
  bool? groupFormed;
  bool? isGroupOwner;

  WifiP2pInfo();

  WifiP2pInfo.fromMap(Map map) {
    groupOwnerAddress = map['groupOwnerAddress'];
    groupFormed = map['groupFormed'];
    isGroupOwner = map['isGroupOwner'];
  }
}
