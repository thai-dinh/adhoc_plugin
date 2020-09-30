abstract class DiscoveryListener {
  void onDeviceDiscovered();

  void onDiscoveryCompleted();

  void onDiscoveryStarted();

  void onDiscoveryFailed(Exception exception);
}