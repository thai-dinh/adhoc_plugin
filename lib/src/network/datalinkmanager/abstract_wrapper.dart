import 'dart:collection';

import 'package:adhoclibrary/src/appframework/config.dart';
import 'package:adhoclibrary/src/datalink/service/adhoc_device.dart';
import 'package:adhoclibrary/src/datalink/service/discovery_event.dart';
import 'package:adhoclibrary/src/datalink/utils/msg_adhoc.dart';


abstract class AbstractWrapper {
  static const CONNECT_SERVER = 10;
  static const CONNECT_CLIENT = 11;
  static const CONNECT_BROADCAST = 12;
  static const DISCONNECT_BROADCAST = 13;
  static const BROADCAST = 14;

  final bool v;
  final HashMap<String, AdHocDevice> mapMacDevices;

  void Function(HashMap<String, AdHocDevice>) listenerBothDiscovery;

  bool enabled;
  bool connectionFlooding;
  bool discoveryCompleted;
  int timeOut;
  int type;
  String label;
  String ownName;
  String ownMac;

  HashSet<AdHocDevice> setRemoteDevices;
  Set<String> setFloodEvents;

  AbstractWrapper(this.v, Config config, this.mapMacDevices) {
    this.enabled = false;
    this.connectionFlooding = config.connectionFlooding;
    this.discoveryCompleted = false;
    this.timeOut = config.timeOut;
    this.setRemoteDevices = HashSet();
    this.setFloodEvents = Set();
    this.label = config.label;
  }

  List<AdHocDevice> get directNeighbors;

  void init(bool verbose, [Config config]);

  void enable(int duration, void Function(bool) onEnable);

  void disable();

  void discovery(void onEvent(DiscoveryEvent event));

  void connect(int attempts, AdHocDevice adHocDevice);

  void stopListening();

  Future<HashMap<String, AdHocDevice>> getPaired();

  Future<String> getAdapterName();

  Future<bool> updateDeviceName(String name);

  Future<bool> resetDeviceName();

  void sendMessage(MessageAdHoc message, String address);

  bool broadcast(MessageAdHoc message);

  bool broadcastExcept(MessageAdHoc message, String excludedAddress);

  bool isDirectNeighbors(String address);

  void disconnect(String remoteDest);

  void disconnectAll();

  bool checkFloodEvent(String id) {
    if (!setFloodEvents.contains(id)) {
      setFloodEvents.add(id);
      return true;
    }

    return false;
  }
}
