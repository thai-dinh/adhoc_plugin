import 'dart:collection';

import 'package:adhoc_plugin/src/appframework/config.dart';
import 'package:adhoc_plugin/src/datalink/exceptions/no_connection.dart';
import 'package:adhoc_plugin/src/datalink/service/adhoc_device.dart';
import 'package:adhoc_plugin/src/datalink/service/service_server.dart';
import 'package:adhoc_plugin/src/datalink/utils/identifier.dart';
import 'package:adhoc_plugin/src/datalink/utils/msg_header.dart';
import 'package:adhoc_plugin/src/datalink/utils/msg_adhoc.dart';
import 'package:adhoc_plugin/src/datalink/utils/utils.dart';
import 'package:adhoc_plugin/src/network/datalinkmanager/abstract_wrapper.dart';
import 'package:adhoc_plugin/src/network/datalinkmanager/flood_msg.dart';
import 'package:adhoc_plugin/src/network/datalinkmanager/neighbors.dart';
import 'package:adhoc_plugin/src/network/datalinkmanager/network_manager.dart';
import 'package:adhoc_plugin/src/network/datalinkmanager/adhoc_event.dart';


abstract class WrapperConnOriented extends AbstractWrapper {
  static const String TAG = "[WrapperConn]";

  HashMap<Identifier, AdHocDevice> _mapMacDevices;

  int attempts;
  Neighbors neighbors;
  ServiceServer serviceServer;

  HashMap<String, NetworkManager> mapAddrNetwork;

  WrapperConnOriented(
    bool verbose, Config config, HashMap<String, AdHocDevice> mapMacDevices,
  ) : super(verbose, config, mapMacDevices) {
    this._mapMacDevices = HashMap();
    this.mapAddrNetwork = HashMap();
    this.neighbors = Neighbors();
  }

/*------------------------------Getters & Setters-----------------------------*/

  List<AdHocDevice> get directNeighbors {
    List<AdHocDevice> devices = List.empty(growable: true);
    for (Identifier macAddress in neighbors.labelMac.values)
      devices.add(_mapMacDevices[macAddress]);

    return devices;
  }

/*-------------------------------Public methods-------------------------------*/

  bool isDirectNeighbors(String remoteLabel) {
    return neighbors.neighbors.containsKey(remoteLabel);
  }

  void sendMessage(MessageAdHoc message, String remoteLabel) {
    NetworkManager network = neighbors.getNeighbor(remoteLabel);
    if (network != null)
      network.sendMessage(message);
  }

  bool broadcast(MessageAdHoc message) {
    if (neighbors.neighbors.length > 0) {
      neighbors.neighbors.values.forEach((network) async {
        if (network != null)
          await network.sendMessage(message);
      });

      return true;
    }

    return false;
  }

  bool broadcastExcept(MessageAdHoc message, String excludedLabel) {
    if (neighbors.neighbors.length > 0) {
      neighbors.neighbors.forEach((remoteLabel, network) async {
        if (excludedLabel.compareTo(remoteLabel) != 0 && network != null) {
          await network.sendMessage(message);
        }
      });

      return true;
    }

    return false;
  }

  void receivedPeerMessage(Header header, NetworkManager network) {
    if (verbose) log(TAG, 'receivedPeerMessage(): ${header.mac}');

    AdHocDevice device = AdHocDevice(
      label: header.label,
      address: header.address,
      name: header.name,
      mac: header.mac,
      type: type
    );

    Iterable<MapEntry<Identifier, AdHocDevice>> it = 
      _mapMacDevices.entries.where(
        (entry) => (header.mac.ble == entry.key.ble || header.mac.wifi == entry.key.wifi)
      );

    if (it.isNotEmpty)
      _mapMacDevices.remove(it.first.value);

    _mapMacDevices.putIfAbsent(header.mac, () => device);

    if (!neighbors.neighbors.containsKey(header.label)) {
      neighbors.addNeighbors(header.label, header.mac, network);

      eventCtrl.add(AdHocEvent(AbstractWrapper.CONNECTION_EVENT, device));

      setRemoteDevices.add(device);
      if (connectionFlooding) {
        String id = header.label + DateTime.now().millisecond.toString();
        setFloodEvents.add(id);
        header.messageType = AbstractWrapper.CONNECT_BROADCAST;
        broadcast(
          MessageAdHoc(header, FloodMsg(id, setRemoteDevices).toJson()),
        );
      }
    }
  }

  void disconnect(String remoteLabel) {
    NetworkManager network = neighbors.getNeighbor(remoteLabel);
    if (network != null) {
      network.disconnect();
      neighbors.remove(remoteLabel);
    }
  }

  void disconnectAll() {
    if (neighbors.neighbors.length > 0) {
      for (NetworkManager network in neighbors.neighbors.values)
        network.disconnect();
      neighbors.clear();
    }
  }

  void connectionClosed(String mac) {
    if (mac == null || mac.compareTo('') == 0)
      return;

    AdHocDevice device;
    Iterable<MapEntry<Identifier, AdHocDevice>> it = 
      _mapMacDevices.entries.where(
        (entry) => (mac == entry.key.ble || mac == entry.key.wifi)
      );
    
    if (it.isEmpty) {
      device = null;
    } else {
      device = it.first.value;
    }

    if (device != null) {
      String label = device.label;

      neighbors.remove(label);
      mapAddrNetwork.remove(device.address);
      _mapMacDevices.removeWhere((identifier, device) => (mac == identifier.ble || mac == identifier.wifi));

      eventCtrl.add(AdHocEvent(AbstractWrapper.BROKEN_LINK, device.label));
      eventCtrl.add(AdHocEvent(AbstractWrapper.DISCONNECTION_EVENT, device));

      if (connectionFlooding) {
        String id = label + DateTime.now().millisecond.toString();
        setFloodEvents.add(id);

        Header header = Header(
          messageType: AbstractWrapper.DISCONNECT_BROADCAST,
          label: label,
          name: device.name,
          mac: device.mac,
          address: device.address,
          deviceType: device.type
        );

        broadcastExcept(MessageAdHoc(header, id), label);

        if (setRemoteDevices.contains(device))
          setRemoteDevices.remove(device);
      }
    } else {
      throw NoConnectionException('Error while closing connection');
    }
  }
}
