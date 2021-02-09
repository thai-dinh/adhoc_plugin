import 'dart:collection';

import 'package:adhoclibrary/src/network/datalinkmanager/network_manager.dart';


class Neighbors {
  HashMap<String, NetworkManager> _neighbors;
  HashMap<String, String> _mapLabelMac;

  Neighbors() {
    this._neighbors = HashMap();
    this._mapLabelMac = HashMap();
  }

/*------------------------------Getters & Setters-----------------------------*/

  HashMap<String, NetworkManager> get neighbors => _neighbors;

  HashMap<String, String> get labelMac => _mapLabelMac;

/*-------------------------------Public methods-------------------------------*/

  void addNeighbors(String label, String mac, NetworkManager network) {
    _neighbors.putIfAbsent(label, () => network);
    _mapLabelMac.putIfAbsent(label, () => mac);
  }

  void remove(String remoteLabel) {
    if (_neighbors.containsKey(remoteLabel)) {
      _mapLabelMac.remove(remoteLabel);
      _neighbors.remove(remoteLabel);
    }
  }

  NetworkManager getNeighbor(String remoteLabel) {
    return _neighbors.containsKey(remoteLabel) ? _neighbors[remoteLabel] : null;
  }

  void clear() {
    _mapLabelMac.clear();
    _neighbors.clear();
  }
}