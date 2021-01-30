import 'dart:collection';

import 'package:adhoclibrary/src/appframework/config.dart';
import 'package:adhoclibrary/src/datalink/service/adhoc_device.dart';
import 'package:adhoclibrary/src/datalink/service/discovery_listener.dart';

abstract class AbstractWrapper {
  final bool verbose;
  final HashMap<String, AdHocDevice> mapMacDevices;

  bool enabled;
  bool discoveryCompleted;
  String label;
  String ownName;
  String ownMac;
  int timeOut;
  int type;
  
  AbstractWrapper(this.verbose, Config config, this.mapMacDevices) {
    this.enabled = true;
    this.discoveryCompleted = false;
    this.label = config.label;
    this.timeOut = config.timeOut;
  }

  void connect(int attempts, AdHocDevice adHocDevice);

  void stopListening();

  void discovery(DiscoveryListener discoveryListener);
}
