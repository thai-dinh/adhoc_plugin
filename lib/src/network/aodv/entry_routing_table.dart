import 'dart:collection';


/// Class representing a routing table entry for AODV protocol.
class EntryRoutingTable {
  late String _destAddress;
  late String _next;
  late int _hop;
  late int _destSeqNum;
  late int _lifetime;
  late List<String> _precursors;
  late HashMap<String, int> _activesDataPath;

  /// Creates an [EntryRoutingTable] object.
  /// 
  /// An entry requires the following parameters:
  /// - [_destAddress]  String value representing the destination address.
  /// - [_next]         String value representing the next hop to reach the 
  ///                   destination address.
  /// - [_hop]          Integer value representing the hops number of the 
  ///                   destination.
  /// - [_destSeqNum]   Integer value representing the sequence number.
  /// - [_lifetime]     Integer value representing the lifetime of the entry.
  /// - [_precursors]   List containing the precursors of the current node.
  EntryRoutingTable(
    this._destAddress, this._next, this._hop, this._destSeqNum, this._lifetime, 
    this._precursors
  ) {
    this._activesDataPath = HashMap();
  }

/*------------------------------Getters & Setters-----------------------------*/

  String get destAddress => _destAddress;

  String get next => _next;

  int get hop => _hop;

  int get destSeqNum => _destSeqNum;

  int get lifetime => _lifetime;

  List<String> get precursors => _precursors;

/*------------------------------Public methods-------------------------------*/

  void updateDataPath(String key) {
    _activesDataPath.putIfAbsent(key, () => DateTime.now().millisecond);
  }

  int getActivesDataPath(String address) {
    if (_activesDataPath.containsKey(address))
      return _activesDataPath[address]!;
    return 0;
  }

  void updatePrecursors(String senderAddr) {
    if (!_precursors.contains(senderAddr))
      _precursors.add(senderAddr);
  }

  String displayPrecursors() { // TODO:
    return '';
  }

/*------------------------------Override methods------------------------------*/

  @override
  String toString() {
    return 'dst: $_destAddress' +
            ' nxt: $_next' +
            ' hop: $_hop' +
            ' seq: $_destSeqNum ${displayPrecursors()}' +
            ' dataPath ${_activesDataPath[_destAddress]}';
  }
}
