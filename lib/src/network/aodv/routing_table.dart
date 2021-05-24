import 'dart:collection';

import 'entry_routing_table.dart';
import '../../datalink/utils/utils.dart';


/// Class representing the routing table of the AODV protocol.
class RoutingTable {
  static const String TAG = '[RoutingTable]';

  final bool _verbose;

  late HashMap<String?, String?> _nextDestMapping;
  late HashMap<String?, EntryRoutingTable?> _routingTable;

  /// Creates a [RoutingTable] object.
  /// 
  /// The debug/verbose mode is set if [_verbose] is true.
  RoutingTable(this._verbose) {
    this._nextDestMapping = HashMap();
    this._routingTable = HashMap();
  }

/*-------------------------------Public methods-------------------------------*/

  /// Adds a new [entry] in the routing table.
  /// 
  /// Returns true if the entry has been added, otherwise false.
  bool addEntry(EntryRoutingTable entry) {
    if (!_routingTable.containsKey(entry.dstAddress)) {
      if (_verbose) log(TAG, 'Add new entry in the RIB ${entry.dstAddress}');

      _routingTable.putIfAbsent(entry.dstAddress, () => entry);
      _nextDestMapping.putIfAbsent(entry.next, () => entry.dstAddress);

      return true;
    }

    EntryRoutingTable existingEntry = _routingTable[entry.dstAddress]!;

    if (existingEntry.hop >= entry.hop) {
      _routingTable.update(entry.dstAddress, (value) => entry);
      _nextDestMapping.update(entry.next, (value) => entry.dstAddress);

      if (_verbose) {
        log(TAG, 'Entry: ${existingEntry.dstAddress}'
              + ' hops: ${existingEntry.hop}'
              + ' is replaced by ${entry.dstAddress}'
              + ' hops: ${entry.hop}');
      }

      return true;
    }

    if (_verbose) {
      log(TAG, 'Entry: ${existingEntry.dstAddress}'
            + ' hops: ${existingEntry.hop}'
            + ' is NOT replaced by ${entry.dstAddress}'
            + ' hops: ${entry.hop}');
    }

    return false;
  }


  /// Removes an entry in the routing table where the entry destination address
  /// matches [dstAddress].
  void removeEntry(String? dstAddress) {
    _routingTable.remove(dstAddress);
  }


  /// Gets an [EntryRoutingTable] entry associated to the destination 
  /// address [dstAddress].
  EntryRoutingTable? getNextFromDest(String? dstAddress) {
    return _routingTable[dstAddress];
  }


  /// Checks whether the destination address [dstAddress] is in the routing 
  /// table.
  /// 
  /// Returns true if it is in the routing table, otherwise false.
  bool containsDest(String? dstAddress) {
    return _routingTable.containsKey(dstAddress);
  }


  /// Checks whether the next hop address [nextAddress] is in the routing table.
  /// 
  /// Returns true if it is in the routing table, otherwise false.
  bool containsNext(String? nextAddress) {
    return _nextDestMapping.containsKey(nextAddress);
  }


  /// Gets the destination address from the next hop address [nextAddress].
  /// 
  /// Returns the destination address.
  String? getDestFromNext(String nextAddress) {
    return _nextDestMapping[nextAddress];
  }


  /// Gets the routing table.
  /// 
  /// Returns a [HashMap] where the key is a [String] and the value is an 
  /// [EntryRoutingTable].
  HashMap<String?, EntryRoutingTable?> getRoutingTable() {
    return _routingTable;
  }


  /// Gets a routing table entry associated to the destination address 
  /// [dstAddress].
  /// 
  /// Returns [EntryRoutingTable] object associated to the destination address.
  EntryRoutingTable? getDestination(String? dstAddress) {
    return _routingTable[dstAddress];
  }


  /// Gets the precursors of a node of destination address [dstAddress].
  /// 
  /// Returns a [List] of [String] representing the precursors list.
  List<String?> getPrecursorsFromDest(String? dstAddress) {
    EntryRoutingTable? entry = _routingTable[dstAddress];
    if (entry != null)
        return entry.precursors;
    return List.empty(growable: true);
  }


  /// Gets the data path from the address [address].
  /// 
  /// Returns an [int] representing the last time the data has been transmitted.
  int getDataPathFromAddress(String? address) {
    EntryRoutingTable? entry = _routingTable[address];
    if (entry != null)
        return entry.getActivesDataPath(address!);
    return 0;
  }
}
