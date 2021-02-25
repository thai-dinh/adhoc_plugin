import 'dart:async';
import 'dart:collection';

import 'package:adhoclibrary/src/appframework/config.dart';
import 'package:adhoclibrary/src/datalink/service/adhoc_device.dart';
import 'package:adhoclibrary/src/datalink/service/discovery_event.dart';
import 'package:adhoclibrary/src/datalink/utils/msg_adhoc.dart';
import 'package:adhoclibrary/src/network/datalinkmanager/wrapper_event.dart';


abstract class AbstractWrapper {
  static const CONNECT_SERVER = 11;
  static const CONNECT_CLIENT = 12;
  static const CONNECT_BROADCAST = 13;
  static const DISCONNECT_BROADCAST = 14;
  static const BROADCAST = 15;

  static const INTERNAL_EXCEPTION = 16;
  static const CONNECTION_EVENT = 17;
  static const DISCONNECTION_EVENT = 18;
  static const DATA_RECEIVED = 19;
  static const FORWARD_DATA = 20;
  static const MESSAGE_EVENT = 21;
  static const BROKEN_LINK = 22;
  static const DEVICE_INFO = 23;

  final bool verbose;
  final HashMap<String, AdHocDevice> mapMacDevices;

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

  StreamController<DiscoveryEvent> discoveryCtrl;
  StreamController<WrapperEvent> eventCtrl;

  AbstractWrapper(this.verbose, Config config, this.mapMacDevices) {
    this.enabled = false;
    this.connectionFlooding = config.connectionFlooding;
    this.discoveryCompleted = false;
    this.timeOut = config.timeOut;
    this.setRemoteDevices = HashSet();
    this.setFloodEvents = Set();
    this.label = config.label;
    this.discoveryCtrl = StreamController<DiscoveryEvent>();
    this.eventCtrl = StreamController<WrapperEvent>();
  }

/*------------------------------Getters & Setters-----------------------------*/

  List<AdHocDevice> get directNeighbors;

  Stream<DiscoveryEvent> get discoveryStream async* {
    await for (DiscoveryEvent event in discoveryCtrl.stream) {
      yield event;
    }
  }

  Stream<WrapperEvent> get eventStream async* {
    await for (WrapperEvent event in eventCtrl.stream) {
      yield event;
    }
  }

/*------------------------------Getters & Setters-----------------------------*/

  void init(bool verbose, [Config config]);

  void enable(int duration, void Function(bool) onEnable);

  void disable();

  void discovery();

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
