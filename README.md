# Ad Hoc Library (adhoc_plugin)

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
- Create a secure group in the ad hoc network
- Join an existing secure group in the ad hoc network
- Leave an existing secure group in the ad hoc network
- Provides notifications of specific events related to the library (e.g., connection established, or data received)

## Application Example

See example.