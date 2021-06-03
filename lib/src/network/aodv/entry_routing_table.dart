import 'dart:collection';


/// Class representing a routing table entry for AODV protocol.
/// 
/// NOTE: Most of the following source code has been borrowed and adapted from 
/// the original codebase provided by Gaulthier Gain, which can be found at:
/// https://github.com/gaulthiergain/AdHocLib
class EntryRoutingTable {
  late final String _dstAddr;
  late final String _next;
  late final int _hop;
  late final int _dstSeqNum;
  late final int _lifetime;
  late final List<String> _precursors;
  late HashMap<String, int> _activesDataPath;

  /// Creates an [EntryRoutingTable] object.
  /// 
  /// An entry requires the following parameters:
  /// - [_dstAddr]      String value representing the destination address.
  /// - [_next]         String value representing the next hop to reach the 
  ///                   destination address.
  /// - [_hop]          Integer value representing the hops number of the 
  ///                   destination.
  /// - [_dstSeqNum]    Integer value representing the sequence number.
  /// - [_lifetime]     Integer value representing the lifetime of the entry.
  /// - [_precursors]   List containing the precursors of the current node.
  EntryRoutingTable(
    this._dstAddr, this._next, this._hop, this._dstSeqNum, this._lifetime, 
    this._precursors
  ) {
    _activesDataPath = HashMap();
  }

/*------------------------------Getters & Setters-----------------------------*/

  /// Returns the destination address stored in this routing table entry.
  String get dstAddr => _dstAddr;

  /// Returns the next hop stored in this routing table entry.
  String get next => _next;

  /// Returns the hops number stored in this routing table entry.
  int get hop => _hop;

  /// Returns the sequence number stored in this routing table entry.
  int get dstSeqNum => _dstSeqNum;

  /// Returns the lifetime of the RREP message stored in this routing table entry.
  int get lifetime => _lifetime;

  /// Returns the list of precursors of this node stored in this routing table
  /// entry.
  List<String> get precursors => _precursors;

/*------------------------------Public methods-------------------------------*/

  /// Updates the data path (active data flow) with the address of a remote 
  /// device [address].
  void updateDataPath(String address) {
    _activesDataPath.putIfAbsent(address, () => DateTime.now().millisecond);
  }


  /// Returns the timestamp where data was forwarded for a particular [address].
  /// 
  /// Returns 0 if the [address] is not found in the active data path.
  int getActivesDataPath(String address) {
    if (_activesDataPath.containsKey(address)) {
      return _activesDataPath[address]!;
    }

    return 0;
  }


  /// Updates the precursors list by adding a node's address [senderAddr] as
  /// a precursor of the current node.
  void updatePrecursors(String senderAddr) {
    if (!_precursors.contains(senderAddr)) {
      _precursors.add(senderAddr);
    }
  }


  /// Displays the list of the precursors of the current node.
  String displayPrecursors() {
    var buffer = StringBuffer();

    buffer.write('precursors: { ');
    for (final precursor in _precursors) {
      buffer.write('$precursor ');
    }

    buffer.write('}');

    return buffer.toString();
  }

/*------------------------------Override methods------------------------------*/

  @override
  String toString() {
    return 'dst: $_dstAddr' +
            ' nxt: $_next' +
            ' hop: $_hop' +
            ' seq: $_dstSeqNum ${displayPrecursors()}' +
            ' dataPath ${_activesDataPath[_dstAddr]}';
  }
}
