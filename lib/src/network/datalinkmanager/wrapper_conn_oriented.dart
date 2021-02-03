import 'dart:collection';

import 'package:adhoclibrary/src/appframework/config/config.dart';
import 'package:adhoclibrary/src/datalink/exceptions/no_connection.dart';
import 'package:adhoclibrary/src/datalink/service/adhoc_device.dart';
import 'package:adhoclibrary/src/datalink/service/service_client.dart';
import 'package:adhoclibrary/src/datalink/service/service_server.dart';
import 'package:adhoclibrary/src/datalink/utils/msg_header.dart';
import 'package:adhoclibrary/src/datalink/utils/msg_adhoc.dart';
import 'package:adhoclibrary/src/network/datalinkmanager/abstract_wrapper.dart';
import 'package:adhoclibrary/src/network/datalinkmanager/flood_msg.dart';
import 'package:adhoclibrary/src/network/datalinkmanager/neighbors.dart';


abstract class WrapperConnOriented extends AbstractWrapper {
  ServiceServer serviceServer;
  Neighbors neighbors;
  int attempts;

  HashMap<String, ServiceClient> mapAddrClient;
  HashMap<String, AdHocDevice> _mapAddrDevices;

  WrapperConnOriented(
    bool verbose, Config config, HashMap<String, AdHocDevice> mapAddressDevice
  ) : super(verbose, config, mapAddressDevice) {
    this.neighbors = Neighbors();
    this._mapAddrDevices = HashMap();
    this.mapAddrClient = HashMap();
  }

/*------------------------------Getters & Setters-----------------------------*/

  List<AdHocDevice> get directNeighbors {
    List<AdHocDevice> devices = List.empty(growable: true);
    for (String macAddress in neighbors.labelMac.values)
      devices.add(_mapAddrDevices[macAddress]);

    return devices;
  }

/*-------------------------------Public methods-------------------------------*/

  bool isDirectNeighbors(String address) {
    return neighbors.neighbors.containsKey(address);
  }

  void sendMessage(MessageAdHoc message, String address) {
    ServiceClient serviceClient = neighbors.getNeighbor(address);
    if (serviceClient != null)
      serviceClient.send(message);
  }

  bool broadcast(MessageAdHoc message) {
    if (neighbors.neighbors.length > 0) {
      for (ServiceClient serviceClient in neighbors.neighbors.values)
        serviceClient.send(message);
      return true;
    }

    return false;
  }

  bool broadcastExcept(MessageAdHoc message, String excludedAddress) {
    if (neighbors.neighbors.length > 0) {
      neighbors.neighbors.forEach((address, serviceClient) {
        if (excludedAddress != address)
          serviceClient.send(message);
      });

      return true;
    }

    return false;
  }

  void receivedPeerMessage(Header header, ServiceClient serviceClient) {
      AdHocDevice adHocDevice = AdHocDevice(
        deviceName: header.name,
        label: header.label,
        type: type
      );

      if (!neighbors.neighbors.containsKey(header.label)) {
        neighbors.addNeighbors(header.label, null, serviceClient);

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

  void disconnect(String address) {
    ServiceClient serviceClient = neighbors.getNeighbor(address);
    if (serviceClient != null) {
      serviceClient.disconnect();
      neighbors.remove(address);
    }
  }

  void disconnectAll() {
    if (neighbors.neighbors.length > 0) {
      for (ServiceClient serviceClient in neighbors.neighbors.values)
        serviceClient.disconnect();
      neighbors.clear();
    }
  }

  void connectionClosed(String remoteAddress) {
    AdHocDevice adHocDevice = _mapAddrDevices[remoteAddress];
    String label = adHocDevice.label;
    if (adHocDevice != null) {
      neighbors.remove(label);
      _mapAddrDevices.remove(remoteAddress);

      if (mapAddrClient.containsKey(remoteAddress))
        mapAddrClient.remove(remoteAddress);

      if (connectionFlooding) {
        String id = label + DateTime.now().millisecond.toString();
        setFloodEvents.add(id);

        Header header = Header(
          messageType: AbstractWrapper.DISCONNECT_BROADCAST,
          label: label,
          name: adHocDevice.deviceName,
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
