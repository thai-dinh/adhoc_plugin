import 'dart:async';
import 'dart:collection';

import 'package:adhoc_plugin/src/appframework/config.dart';
import 'package:adhoc_plugin/src/datalink/exceptions/no_connection.dart';
import 'package:adhoc_plugin/src/datalink/service/adhoc_device.dart';
import 'package:adhoc_plugin/src/datalink/service/adhoc_event.dart';
import 'package:adhoc_plugin/src/datalink/service/constants.dart';
import 'package:adhoc_plugin/src/datalink/service/service_server.dart';
import 'package:adhoc_plugin/src/datalink/utils/identifier.dart';
import 'package:adhoc_plugin/src/datalink/utils/msg_adhoc.dart';
import 'package:adhoc_plugin/src/datalink/utils/msg_header.dart';
import 'package:adhoc_plugin/src/datalink/utils/utils.dart';
import 'package:adhoc_plugin/src/network/datalinkmanager/constants.dart';
import 'package:adhoc_plugin/src/network/datalinkmanager/flood_msg.dart';
import 'package:adhoc_plugin/src/network/datalinkmanager/neighbors.dart';
import 'package:adhoc_plugin/src/network/datalinkmanager/network_manager.dart';

/// Super abstract class defining the parameters and methods for managing
/// connections, messages received. It aims to serve as a common interface for
/// the service classes 'WrapperBle' and 'WrapperWifi'.
///
/// NOTE: Most of the following source code has been borrowed and adapted from
/// the original codebase provided by Gaulthier Gain, which can be found at:
/// https://github.com/gaulthiergain/AdHocLib
abstract class WrapperNetwork {
  static const String TAG = "[WrapperNetwork]";

  final bool verbose;

  late int type;
  late String ownLabel;
  late String ownName;
  late Identifier ownMac;

  late bool flood;
  late int timeOut;
  late int attempts;

  late bool enabled;
  late bool discoveryCompleted;
  late bool isDiscovering;
  late bool isListening;
  late Neighbors neighbors;

  late ServiceServer serviceServer;

  late HashMap<String, NetworkManager> mapAddrNetwork;
  late HashMap<Identifier, AdHocDevice> mapMacDevices;

  late Set<String> setFloodEvents;
  late HashSet<AdHocDevice> setRemoteDevices;

  late StreamController<AdHocEvent> controller;

  /// Creates a [WrapperNetwork] object.
  ///
  /// The debug/verbose mode is set if [verbose] is true.
  ///
  /// This object is configured according to [config], which contains specific
  /// configurations.
  ///
  /// This object maps a MAC address entry ([Identifier]) to an [AdHocDevice] object
  /// into [mapMacDevices].
  WrapperNetwork(
    this.verbose,
    Config config,
    HashMap<Identifier, AdHocDevice> mapMacDevices,
  ) {
    this.mapMacDevices = mapMacDevices;
    flood = config.flood;
    timeOut = config.timeOut;
    attempts = 3;
    ownLabel = config.label;
    ownName = '';
    ownMac = Identifier();
    type = -1;
    enabled = false;
    discoveryCompleted = false;
    isDiscovering = false;
    isListening = false;
    neighbors = Neighbors();
    mapAddrNetwork = HashMap();
    controller = StreamController<AdHocEvent>();
    setFloodEvents = <String>{};
    setRemoteDevices = HashSet();
  }

/*------------------------------Getters & Setters-----------------------------*/

  /// Direct neighbors of this node.
  List<AdHocDevice> get directNeighbors {
    var devices = List<AdHocDevice>.empty(growable: true);
    for (final mac in neighbors.labelMac.values) {
      devices.add(mapMacDevices[mac]!);
    }

    return devices;
  }

  /// Stream of lower layer events
  Stream<AdHocEvent> get eventStream => controller.stream;

/*------------------------------Abstract methods------------------------------*/

  /// Initializes internal parameters.
  ///
  /// The debug/verbose mode is set if [verbose] is true.
  ///
  /// This object is configured according to [config], which contains specific
  /// configurations.
  void init(bool verbose, Config? config);

  /// Enables a technology and sets it in discovery mode.
  ///
  /// The discovery mode lasts for [duration] ms.
  void enable(int duration);

  /// Disables a technology.
  void disable();

  /// Triggers a discovery process.
  void discovery();

  /// Connects to a remote peer.
  ///
  /// The remote peer is specified by [device] and the connection attempts is
  /// set to [attempts].
  Future<void> connect(int attempts, AdHocDevice device);

  /// Gets all the Bluetooth devices which are already paired.
  ///
  /// Returns a hash map (<[String], [AdHocDevice]>) containing the paired
  /// devices.
  Future<HashMap<String, AdHocDevice>> getPaired();

  /// Gets the adapter name.
  ///
  /// Returns a [String] representing the adapter name.
  Future<String> getAdapterName();

  /// Updates the adapter name of the device with [name].
  ///
  /// Returns true if the name is successfully set, otherwise false.
  Future<bool> updateDeviceName(String name);

  /// Resets the adapter name of the device.
  ///
  /// Returns true if the name is successfully reset, otherwise false.
  Future<bool> resetDeviceName();

/*-------------------------------Public methods-------------------------------*/

  /// Closes the stream controller.
  void stopListening() {
    controller.close();
  }

  /// Checks if a message has been already received if the connection flooding
  /// option is enabled.
  ///
  /// The identifier [id] represents a unique identifier to the flood message.
  ///
  /// Returns true if the message is received for the first time, otherwise
  /// false.
  bool checkFloodEvent(String id) {
    if (!setFloodEvents.contains(id)) {
      setFloodEvents.add(id);
      return true;
    }

    return false;
  }

  /// Checks if a node with address [label] is a direct neighbor.
  ///
  /// Returns true if it is, otherwise false.
  bool isDirectNeighbor(String label) {
    return neighbors.neighbors.containsKey(label);
  }

  /// Send a message to a remote peer.
  ///
  /// The message to sent is given by [message] and its destination address is
  /// set to [label]
  void sendMessage(String label, MessageAdHoc message) {
    var network = neighbors.getNeighbor(label);
    if (network != null) {
      network.sendMessage(message);
    }
  }

  /// Broadcasts a message to all directly connected nodes.
  ///
  /// Returns true if the [message] has been successfully broadcasted, otherwise
  /// false.
  Future<bool> broadcast(MessageAdHoc message) async {
    if (neighbors.neighbors.isNotEmpty) {
      for (var network in neighbors.neighbors.values) {
        await network.sendMessage(message);
      }

      return true;
    }

    return false;
  }

  /// Broadcasts a message to all directly connected nodes except the excluded
  /// node.
  ///
  /// Returns true if the [message] has been successfully broadcasted to all
  /// direct neighbors except [excluded], otherwise false.
  bool broadcastExcept(MessageAdHoc message, String excluded) {
    if (neighbors.neighbors.isNotEmpty) {
      neighbors.neighbors.forEach((label, network) async {
        if (excluded.compareTo(label) != 0) {
          await network.sendMessage(message);
        }
      });

      return true;
    }

    return false;
  }

  /// Processes a message received from a remote node.
  ///
  /// The information of the remote node is determined by [header] and a
  /// [network] ([NetworkManager]) object is used to perform network operations
  /// with the remote node.
  void receivedPeerMessage(Header header, NetworkManager network) {
    if (verbose) log(TAG, 'receivedPeerMessage(): ${header.mac}');

    // Recover the AdHocDevice of the remote node
    var device = AdHocDevice(
      label: header.label,
      address: header.address,
      name: header.name,
      mac: header.mac,
      type: header.deviceType!
    );

    // Add mapping MAC address (String) - device (AdHocDevice)
    for (final id in mapMacDevices.keys) {
      if (id.ble == header.mac.ble || id.wifi == header.mac.wifi) {
        mapMacDevices.remove(id);
        break;
      }
    }

    mapMacDevices.putIfAbsent(header.mac, () => device);

    // Check if the device is already in neighbors list
    if (!neighbors.neighbors.containsKey(header.label)) {
      // Add the new neighbor
      neighbors.addNeighbor(header.label, header.mac, network);

      // Notify upper layer of a connection establishment
      controller.add(AdHocEvent(CONNECTION_PERFORMED, device));

      // Update the set
      setRemoteDevices.add(device);

      // If connection flooding option is enable, floods the connection event
      if (flood) {
        var id = header.label + DateTime.now().millisecond.toString();
        setFloodEvents.add(id);
        header.messageType = CONNECT_BROADCAST;
        broadcast(
          MessageAdHoc(header, FloodMsg(id, setRemoteDevices).toJson()),
        );
      }
    } else {
      // Update MAC address if already present
      neighbors.updateNeighbor(header.label, header.mac);
    }
  }

  /// Disconnects the node from a particular node denoted by [label].
  void disconnect(String label) {
    var network = neighbors.getNeighbor(label);
    if (network != null) {
      network.disconnect();
      neighbors.remove(label);
    }
  }

  /// Disconnects the node from all remote node.
  void disconnectAll() {
    if (neighbors.neighbors.isNotEmpty) {
      for (NetworkManager? network in neighbors.neighbors.values) {
        if (network != null) {
          network.disconnect();
        }
      }

      neighbors.clear();
    }
  }

  /// Processes the disconnection of a remote node with MAC address [mac].
  void connectionClosed(Identifier mac) {
    AdHocDevice? device;
    // Get AdHocDevice from the MAC address
    for (final id in mapMacDevices.keys) {
      if (id.ble == mac.ble || id.wifi == mac.wifi) {
        device = mapMacDevices[id];
        break;
      }
    }

    if (device != null) {
      var label = device.label;

      // Remove device from neighbors and hash maps
      neighbors.remove(label!);
      mapAddrNetwork.remove(device.address);
      mapMacDevices.remove(device.mac);

      // Notify upper layer of a broken link detected as well as a disconnection
      // event
      controller.add(AdHocEvent(BROKEN_LINK, device.label));
      controller.add(AdHocEvent(CONNECTION_ABORTED, device));

      // If the connection flooding option is enable, floods the disconnect event
      if (flood) {
        var id = label + DateTime.now().millisecond.toString();
        setFloodEvents.add(id);

        var header = Header(
          messageType: DISCONNECT_BROADCAST,
          label: label,
          name: device.name,
          mac: device.mac,
          address: device.address,
          deviceType: device.type
        );

        broadcastExcept(MessageAdHoc(header, id), label);

        // Update the set
        if (setRemoteDevices.contains(device)) {
          setRemoteDevices.remove(device);
        }
      }
    } else {
      throw NoConnectionException('Error while closing connection');
    }
  }
}
