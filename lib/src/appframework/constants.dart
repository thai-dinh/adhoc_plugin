/// Enum defining the type of events
enum AdHocType {
  /// Device discovered (either Wi-Fi or Bluetooth enabled)
  onDeviceDiscovered,

  /// Start discovery process of peers
  onDiscoveryStarted,

  /// End of discovery process
  onDiscoveryCompleted,

  /// Data received from peers
  onDataReceived,

  /// Data to be forward to peers
  onForwardData,

  /// Successful connection to a peer
  onConnection,

  /// Connection aborted
  onConnectionClosed,

  /// Exception raised in lower layer of the library
  onInternalException,

  /// Update on the secure group
  onGroupInfo,

  /// Data received from a group member
  onGroupDataReceived,
}

/// Minimum value allowed for the socket port (Wi-Fi Direct)
const MIN_PORT = 1023;

/// Maximum value allowed for the socket port (Wi-Fi Direct)
const MAX_PORT = 65535;
