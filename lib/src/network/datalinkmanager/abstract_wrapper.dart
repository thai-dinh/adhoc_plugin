import 'dart:collection';

import 'package:adhoclibrary/src/appframework/config/config.dart';
import 'package:adhoclibrary/src/datalink/service/adhoc_device.dart';
import 'package:adhoclibrary/src/datalink/service/discovery_listener.dart';

abstract class AbstractWrapper {
  static const CONNECT_SERVER = 10;
  static const CONNECT_CLIENT = 11;
  static const CONNECT_BROADCAST = 12;
  static const DISCONNECT_BROADCAST = 13;
  static const BROADCAST = 14;

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

  Future<HashMap<String, AdHocDevice>> getPaired();

  void enable(int duration);

  void disable();

  Future<bool> resetDeviceName();

  Future<bool> updateDeviceName(String name);

  Future<String> getAdapterName();
}
