import 'dart:collection';

import 'package:adhoclibrary/src/appframework/config.dart';
import 'package:adhoclibrary/src/datalink/exceptions/no_connection.dart';
import 'package:adhoclibrary/src/datalink/service/adhoc_device.dart';
import 'package:adhoclibrary/src/datalink/service/service_server.dart';
import 'package:adhoclibrary/src/datalink/utils/msg_header.dart';
import 'package:adhoclibrary/src/datalink/utils/msg_adhoc.dart';
import 'package:adhoclibrary/src/network/datalinkmanager/abstract_wrapper.dart';
import 'package:adhoclibrary/src/network/datalinkmanager/flood_msg.dart';
import 'package:adhoclibrary/src/network/datalinkmanager/neighbors.dart';
import 'package:adhoclibrary/src/network/datalinkmanager/network_manager.dart';
import 'package:adhoclibrary/src/network/datalinkmanager/adhoc_event.dart';


abstract class WrapperConnOriented extends AbstractWrapper {
  HashMap<String, AdHocDevice> _mapMacDevices;

  HashMap<String, NetworkManager> mapAddrNetwork;
  int attempts;
  Neighbors neighbors;
  ServiceServer serviceServer;

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
    for (String macAddress in neighbors.labelMac.values)
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
        await network.sendMessage(message);
      });

      return true;
    }

    return false;
  }

  bool broadcastExcept(MessageAdHoc message, String excludedLabel) {
    if (neighbors.neighbors.length > 0) {
      neighbors.neighbors.forEach((remoteLabel, network) async {
        if (excludedLabel.compareTo(remoteLabel) != 0) {
          await network.sendMessage(message);
        }
      });

      return true;
    }

    return false;
  }

  void receivedPeerMessage(Header header, NetworkManager network) {
    AdHocDevice adHocDevice = AdHocDevice(
      label: header.label,
      address: header.address,
      name: header.name,
      mac: header.mac,
      type: type
    );

    _mapMacDevices.putIfAbsent(header.mac, () => adHocDevice);

    if (!neighbors.neighbors.containsKey(header.label)) {
      neighbors.addNeighbors(header.label, header.mac, network);

      setRemoteDevices.add(adHocDevice);
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

    AdHocDevice adHocDevice = _mapMacDevices[mac];
    if (adHocDevice != null) {
      String label = adHocDevice.label;

      neighbors.remove(mac);
      mapAddrNetwork.remove(adHocDevice.address);
      _mapMacDevices.remove(mac);

      eventCtrl.add(AdHocEvent(AbstractWrapper.BROKEN_LINK, adHocDevice.label));
      eventCtrl.add(AdHocEvent(AbstractWrapper.DISCONNECTION_EVENT, adHocDevice));

      if (connectionFlooding) {
        String id = label + DateTime.now().millisecond.toString();
        setFloodEvents.add(id);

        Header header = Header(
          messageType: AbstractWrapper.DISCONNECT_BROADCAST,
          label: label,
          name: adHocDevice.name,
          mac: adHocDevice.mac,
          address: adHocDevice.address,
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
