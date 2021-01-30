import 'dart:collection';

import 'package:adhoclibrary/src/datalink/service/adhoc_device.dart';

abstract class DiscoveryListener {
  void onDeviceDiscovered(AdHocDevice device);

  void onDiscoveryCompleted(HashMap<String, AdHocDevice> mapNameDevice);

  void onDiscoveryStarted();

  void onDiscoveryFailed(Exception exception);
}
