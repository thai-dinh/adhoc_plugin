import 'dart:collection';

import 'package:adhoc_plugin/src/network/datalinkmanager/network_manager.dart';


/// Class managing the direct neighbors of a node
class Neighbors {
  late HashMap<String?, NetworkManager?> _neighbors;
  late HashMap<String?, String?> _mapLabelMac;

  /// Initialize an instance of Neighbors
  Neighbors() {
    this._neighbors = HashMap();
    this._mapLabelMac = HashMap();
  }

/*------------------------------Getters & Setters-----------------------------*/

  ///
  HashMap<String?, NetworkManager?> get neighbors => _neighbors;

  ///
  HashMap<String?, String?> get labelMac => _mapLabelMac;

/*-------------------------------Public methods-------------------------------*/

  /// Add a direct neighbors whose label is [label], MAC address is [mac], and
  /// NetworkManager as [network]
  void addNeighbors(String? label, String? mac, NetworkManager? network) {
    _neighbors.putIfAbsent(label, () => network);
    _mapLabelMac.putIfAbsent(label, () => mac);
  }

  /// Remove the entry of the hashmap [_mapLabelMac] where [label] is the key
  void remove(String? label) {
    if (_neighbors.containsKey(label)) {
      _mapLabelMac.remove(label);
      _neighbors.remove(label);
    }
  }

  /// Get the NetworkManager object associated to key [label]
  NetworkManager? getNeighbor(String? label) {
    return _neighbors.containsKey(label) ? _neighbors[label] : null;
  }

  /// Clear the content of the data structure
  void clear() {
    _mapLabelMac.clear();
    _neighbors.clear();
  }
}