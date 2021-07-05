import 'dart:collection';

import 'package:adhoc_plugin/src/datalink/utils/identifier.dart';
import 'package:adhoc_plugin/src/network/datalinkmanager/network_manager.dart';

/// Class managing the direct neighbors of a node.
class Neighbors {
  late HashMap<String, NetworkManager> _neighbors;
  late HashMap<String, Identifier> _mapLabelMac;

  /// Creates a [Neighbors] object.
  Neighbors() {
    _neighbors = HashMap();
    _mapLabelMac = HashMap();
  }

/*------------------------------Getters & Setters-----------------------------*/

  /// Direct neighbors of a node as a [HashMap] of <[String], [NetworkManager]>.
  HashMap<String, NetworkManager> get neighbors => _neighbors;

  /// Direct neighbors of a node as a [HashMap] of <[String], [Identifier]>,
  /// where the key is the label and the value the MAC address of the neighbor.
  HashMap<String, Identifier> get labelMac => _mapLabelMac;

/*-------------------------------Public methods-------------------------------*/

  /// Add a direct neighbors whose label is [label], MAC address is [mac], and
  /// NetworkManager as [network]
  void addNeighbor(String label, Identifier mac, NetworkManager network) {
    _neighbors.putIfAbsent(label, () => network);
    _mapLabelMac.putIfAbsent(label, () => mac);
  }

  /// Removes the entry of the hashmap [_mapLabelMac] where [label] is the key
  void remove(String label) {
    if (_neighbors.containsKey(label)) {
      _mapLabelMac.remove(label);
      _neighbors.remove(label);
    }
  }

  /// Updates the MAC address of a neighbor.
  ///
  /// The neighbor identified by [label] is getting its MAC updated by [mac].
  void updateNeighbor(String label, Identifier mac) {
    _mapLabelMac.update(label, (value) => mac);
  }

  /// Gets the NetworkManager object associated to key [label].
  ///
  /// Returns the associated [NetworkManager] to [label]. The returned value is
  /// null if no match is found.
  NetworkManager? getNeighbor(String label) {
    return _neighbors.containsKey(label) ? _neighbors[label] : null;
  }

  /// Clears the content of the data structure.
  void clear() {
    _mapLabelMac.clear();
    _neighbors.clear();
  }
}
