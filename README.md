# Ad Hoc Library (adhoc_plugin)

[![Pub Package](https://img.shields.io/pub/v/adhoc_plugin.svg)](https://pub.dev/packages/adhoc_plugin)

Flutter plugin that handles ad hoc network operations for Android mobile devices.

This library is a ported version in Dart of the AdHocLibrary project developed by [Gaulthier Gain](https://github.com/gaulthiergain). The original version works with both Bluetooth and Wi-Fi Direct whereas the ported version supports Bluetooth Low Energy (only) and Wi-Fi Direct. Some classes have been kept as-is with minor modifications as those were not available in the Flutter framework, e.g., Android Wi-Fi Direct APIs. The original project can be found at the following link [AdHocLib](https://github.com/gaulthiergain/AdHocLib).

This version is designed for my master thesis at the Université de Liège (Montefiore Institute). In addition to porting the original project, new security functionalities have been added such as the ability to send encrypted data to a remote peer.

## Usage

The ad hoc library supports the following operations:
- Create an ad hoc network
- Join an ad hoc network
- Leave an ad hoc network
- Send data in plain-text to a remote destination (use ad hoc routing algorithm (AODV) if needed)
- Send encrypted data to a remote destination (use ad hoc routing algorithm (AODV) if needed)
- Forward data to another node of the network (use ad hoc routing algorithm (AODV) if needed)
- Broadcast data in plain-text to all directly connected neighbors
- Broadcast encrypted data to all directly connected neighbors
- Revoke its certificate (private key compromised)
- Create a secure group
- Join an existing secure group
- Leave an existing secure group
- Send encrypted data to an existing secure group
- Provides notifications of specific events related to the library (e.g., connection established, or data received)

### TransferManager

To initialise the library, it is done as follows:
```dart
bool verbose = true;
TransferManager transferManager = TransferManager(verbose);
```

It is also possible to modify the behaviour of the library by configuring a __Config__ object.

```dart
bool verbose = false;
Config config = Config();

config.label = "Example name"; // Use for communication
config.public = true; // Join any group formation

TransferManager transferManager = TransferManager(verbose, config);
```

### Listen to events

As different events can occurs in the ad hoc network, the broadcast stream exposed by __TransferManager__ can be listen to.

```dart
TransferManager transferManager = TransferManager(false);

void _listen() {
  _manager.eventStream.listen((event) {
    switch (event.type) {
      case AdHocType.onDeviceDiscovered:
        var device = event.device as AdHocDevice;
        break;
      case AdHocType.onDiscoveryStarted:
        break;
      case AdHocType.onDiscoveryCompleted:
        var discovered = event.data as Map<String?, AdHocDevice?>
        break;
      case AdHocType.onDataReceived:
        var data = event.data as Object;
        break;
      case AdHocType.onForwardData:
        var data = event.data as Object;
        break;
      case AdHocType.onConnection:
        var device = event.device as AdHocDevice;
        break;
      case AdHocType.onConnectionClosed:
        var device = event.device as AdHocDevice;
        break;
      case AdHocType.onInternalException:
        var exception = event.data as Exception;
        break;
      case AdHocType.onGroupInfo:
        var info = event.data as int;
        break;
      case AdHocType.onGroupDataReceived:
        var data = event.data as Object;
        break;
      default:
    }
  }
}
```

## Application Example

### Music App Sharing

- [Source code](example)

An example showing how to use the library APIs.

### Video (demo)

- [Demo](https://vimeo.com/571293323)

Example of message app.

## Notes

Note that some mobile devices might support partially Bluetooth Low Energy (support BLE GATT server, but not advertisement) or in some case not at all (transfering big file with BLE takes very long time).

Further information about the implementation and library architecture can be found at the following [address (master thesis)](https://matheo.uliege.be/handle/2268.2/11450) (https://matheo.uliege.be/handle/2268.2/11450)

This library will not be updated anymore, but feel free to submit bug reports, feature requests, or pull requests, which will be handled.
