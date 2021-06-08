enum AdHocType {
  onDeviceDiscovered,
  onDiscoveryStarted,
  onDiscoveryCompleted,
  onDataReceived,
  onForwardData,
  onConnection,
  onConnectionClosed,
  onInternalException,
  onGroupInfo,
  onGroupDataReceived,
}

/// Minimum value allowed for the socket port (Wi-Fi Direct)
const MIN_PORT = 1023;

/// Maximum value allowed for the socket port (Wi-Fi Direct)
const MAX_PORT = 65535;
