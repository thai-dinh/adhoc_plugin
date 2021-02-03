import 'dart:collection';

import 'package:adhoclibrary/src/datalink/service/service_client.dart';


class Neighbors {
  HashMap<String, String> _mapLabelMac;
  HashMap<String, ServiceClient>  _neighbors;

  Neighbors() {
    this._mapLabelMac = HashMap();
    this._neighbors = HashMap();
  }

/*------------------------------Getters & Setters-----------------------------*/

  HashMap<String, ServiceClient> get neighbors => _neighbors;

  HashMap<String, String> get labelMac => _mapLabelMac;

/*-------------------------------Public methods-------------------------------*/

  void addNeighbors(String label, String mac, ServiceClient serviceClient) {
    _mapLabelMac.putIfAbsent(label, () => mac);
    _neighbors.putIfAbsent(label, () => serviceClient);
  }

  void remove(String remoteLabel) {
    if (_neighbors.containsKey(remoteLabel)) {
      _neighbors.remove(remoteLabel);
      _mapLabelMac.remove(remoteLabel);
    }
  }

  ServiceClient getNeighbor(String remoteLabel) {
    return _neighbors.containsKey(remoteLabel) ? _neighbors[remoteLabel] : null;
  }

  void clear() {
    _neighbors.clear();
    _mapLabelMac.clear();
  }
}
