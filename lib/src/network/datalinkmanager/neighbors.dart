import 'dart:collection';


class Neighbors {
  HashMap<String, Null>  _neighbors; // SocketManager
  HashMap<String, String> _mapLabelMac;

  Neighbors() {
    this._mapLabelMac = HashMap<String, String>();
  }

/*------------------------------Getters & Setters-----------------------------*/

  Map get neighbors => _neighbors;

  HashMap<String, String> get labelMac => _mapLabelMac;

/*-------------------------------Public methods-------------------------------*/

  void addNeighbors(String label, String mac) { // TODO: modify instead of socketmanager
    _mapLabelMac.putIfAbsent(label, () => mac);
  }

  void remove(String remoteLabel) {
    if (_neighbors.containsKey(remoteLabel)) {
      _neighbors.remove(remoteLabel);
      _mapLabelMac.remove(remoteLabel);
    }
  }

  dynamic getNeighbor(String remoteLabel) {
    return _neighbors.containsKey(remoteLabel) ? _neighbors[remoteLabel] : null;
  }

  void clear() {
    _neighbors.clear();
    _mapLabelMac.clear();
  }
}
