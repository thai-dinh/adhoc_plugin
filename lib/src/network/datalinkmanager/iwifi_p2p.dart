abstract class IWifiP2P {
  void setGroupOwnerValue(int valueGroupOwner);

  void removeGroup();

  void cancelConnect();

  bool isWifiGroupOwner();
}
