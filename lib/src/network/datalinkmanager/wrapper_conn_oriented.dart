import 'dart:collection';

import 'package:adhoclibrary/src/appframework/config.dart';
import 'package:adhoclibrary/src/appframework/listener_app.dart';
import 'package:adhoclibrary/src/datalink/exceptions/no_connection.dart';
import 'package:adhoclibrary/src/datalink/service/adhoc_device.dart';
import 'package:adhoclibrary/src/datalink/service/service_server.dart';
import 'package:adhoclibrary/src/datalink/utils/msg_header.dart';
import 'package:adhoclibrary/src/datalink/utils/msg_adhoc.dart';
import 'package:adhoclibrary/src/network/datalinkmanager/abstract_wrapper.dart';
import 'package:adhoclibrary/src/network/datalinkmanager/flood_msg.dart';
import 'package:adhoclibrary/src/network/datalinkmanager/neighbors.dart';
import 'package:adhoclibrary/src/network/datalinkmanager/network_manager.dart';


abstract class WrapperConnOriented extends AbstractWrapper {
  HashMap<String, AdHocDevice> _mapAddrDevices;

  HashMap<String, NetworkManager> mapAddrNetwork;
  ServiceServer serviceServer;
  Neighbors neighbors;
  int attempts;

  WrapperConnOriented(
    bool verbose, Config config, HashMap<String, AdHocDevice> mapMacDevices,
    ListenerApp listenerApp
  ) : super(verbose, config, mapMacDevices, listenerApp) {
    this._mapAddrDevices = HashMap();
    this.mapAddrNetwork = HashMap();
    this.neighbors = Neighbors();
  }

/*------------------------------Getters & Setters-----------------------------*/

  List<AdHocDevice> get directNeighbors {
    List<AdHocDevice> devices = List.empty(growable: true);
    for (String macAddress in neighbors.labelMac.values)
      devices.add(_mapAddrDevices[macAddress]);

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
      for (NetworkManager network in neighbors.neighbors.values)
        network.sendMessage(message);
      return true;
    }

    return false;
  }

  bool broadcastExcept(MessageAdHoc message, String excludedAddress) {
    if (neighbors.neighbors.length > 0) {
      neighbors.neighbors.forEach((remoteLabel, network) {
        if (excludedAddress != remoteLabel)
          network.sendMessage(message);
      });

      return true;
    }

    return false;
  }


  void receivedPeerMessage(Header header, NetworkManager network) {
    AdHocDevice adHocDevice = AdHocDevice(
      label: header.label,
      name: header.name,
      mac: header.mac,
      type: type
    );

    mapMacDevices.putIfAbsent(header.mac, () => adHocDevice);

    if (!neighbors.neighbors.containsKey(header.label)) {
      neighbors.addNeighbors(header.label, header.mac, network);

      listenerApp.onConnection(adHocDevice);

      setRemoteDevices.add(adHocDevice);

      if (connectionFlooding) {
        String id = label + DateTime.now().millisecond.toString();
        setFloodEvents.add(id);

        header.messageType = AbstractWrapper.CONNECT_BROADCAST;
        broadcastExcept(MessageAdHoc(header, id), label);
        sendMessage(
          MessageAdHoc(header, FloodMsg(id, setRemoteDevices)),
          header.label
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


  void connectionClosed(String remoteLabel) {
    AdHocDevice adHocDevice = _mapAddrDevices[remoteLabel];
    if (adHocDevice != null) {
      String label = adHocDevice.label;

      _mapAddrDevices.remove(remoteLabel);
      mapAddrNetwork.remove(remoteLabel);
      neighbors.remove(label);

      listenerApp.onConnectionClosed(adHocDevice);

      if (connectionFlooding) {
        String id = label + DateTime.now().millisecond.toString();
        setFloodEvents.add(id);

        Header header = Header(
          messageType: AbstractWrapper.DISCONNECT_BROADCAST,
          label: label,
          name: adHocDevice.name,
          mac: adHocDevice.mac,
          deviceType: adHocDevice.type
        );

        broadcastExcept(MessageAdHoc(header, id), label);

        if (setRemoteDevices.contains(adHocDevice))
          setRemoteDevices.remove(adHocDevice);
      }
    } else {
      throw NoConnectionException('Error while closing connection');
    }
  }
}
