import 'dart:collection';

import 'package:adhoclibrary/src/appframework/config/config.dart';
import 'package:adhoclibrary/src/datalink/service/adhoc_device.dart';
import 'package:adhoclibrary/src/datalink/service/service_server.dart';
import 'package:adhoclibrary/src/network/datalinkmanager/abstract_wrapper.dart';
import 'package:adhoclibrary/src/datalink/utils/msg_adhoc.dart';
import 'package:adhoclibrary/src/network/datalinkmanager/neighbors.dart';


abstract class WrapperConnOriented extends AbstractWrapper {
  int attempts;
  Neighbors neighbors;
  ServiceServer serviceServer;

  WrapperConnOriented(
    bool verbose, Config config, HashMap<String, AdHocDevice> mapAddressDevice
  ) : super(verbose, config, mapAddressDevice) {

    this.neighbors = Neighbors();
  }

/*-------------------------------Public methods-------------------------------*/

  void sendMessage(MessageAdHoc message, String address) {

  }

  bool broadcast(MessageAdHoc message) {
    if (neighbors.neighbors.length > 0) {
      for (var entry in neighbors.neighbors.values)
        entry.sendMessage(message);

      return true;
    }

    return false;
  }

  bool broadcastExcept(MessageAdHoc message, String excludedAddress) {
    if (neighbors.neighbors.length > 0) {
      neighbors.neighbors.forEach((key, value) {
        if (key != excludedAddress)
          value.sendMessage(message);
      });

      return true;
    }

    return false;
  }

  bool isDirectNeighbors(String address) {
    return neighbors.neighbors.containsKey(address);
  }

  void disconnect(String remoteDest) {

  }

  void disconnectAll() {
    if (neighbors.neighbors.length > 0) {
      for (var entry in neighbors.neighbors.values)
        entry.closeConnection();
      neighbors.clear();
    }
  }
}
