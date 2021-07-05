import 'dart:collection';

import 'package:adhoc_plugin/src/datalink/utils/utils.dart';
import 'package:adhoc_plugin/src/network/aodv/entry_routing_table.dart';

/// Class representing the routing table of the AODV protocol.
///
/// NOTE: Most of the following source code has been borrowed and adapted from
/// the original codebase provided by Gaulthier Gain, which can be found at:
/// https://github.com/gaulthiergain/AdHocLib
class RoutingTable {
  static const String TAG = '[RoutingTable]';

  final bool _verbose;

  late HashMap<String?, String?> _nextDestMapping;
  late HashMap<String?, EntryRoutingTable?> _routingTable;

  /// Creates a [RoutingTable] object.
  ///
  /// The debug/verbose mode is set if [_verbose] is true.
  RoutingTable(this._verbose) {
    _nextDestMapping = HashMap();
    _routingTable = HashMap();
  }

/*------------------------------Getters & Setters-----------------------------*/

  /// The routing table as a [HashMap] where the key is a [String] and the value is an
  /// [EntryRoutingTable].
  HashMap<String?, EntryRoutingTable?> get routingTable {
    return _routingTable;
  }

/*-------------------------------Public methods-------------------------------*/

  /// Adds a new [entry] in the routing table.
  ///
  /// Returns true if the entry has been added, otherwise false.
  bool addEntry(EntryRoutingTable entry) {
    if (!_routingTable.containsKey(entry.dstAddr)) {
      if (_verbose) log(TAG, 'Add new entry in the RIB ${entry.dstAddr}');

      _routingTable.putIfAbsent(entry.dstAddr, () => entry);
      _nextDestMapping.putIfAbsent(entry.next, () => entry.dstAddr);

      return true;
    }

    var existingEntry = _routingTable[entry.dstAddr]!;

    if (existingEntry.hop >= entry.hop) {
      _routingTable.putIfAbsent(entry.dstAddr, () => entry);
      _nextDestMapping.putIfAbsent(entry.next, () => entry.dstAddr);

      if (_verbose) {
        log(
            TAG,
            'Entry: ${existingEntry.dstAddr}' +
                ' hops: ${existingEntry.hop}' +
                ' is replaced by ${entry.dstAddr}' +
                ' hops: ${entry.hop}');
      }

      return true;
    }

    if (_verbose) {
      log(
          TAG,
          'Entry: ${existingEntry.dstAddr}' +
              ' hops: ${existingEntry.hop}' +
              ' is NOT replaced by ${entry.dstAddr}' +
              ' hops: ${entry.hop}');
    }

    return false;
  }

  /// Removes an entry in the routing table where the entry destination address
  /// matches [dstAddr].
  void removeEntry(String? dstAddr) {
    _routingTable.remove(dstAddr);
  }

  /// Gets an [EntryRoutingTable] entry associated to the destination
  /// address [dstAddr].
  EntryRoutingTable? getNextFromDest(String? dstAddr) {
    return _routingTable[dstAddr];
  }

  /// Checks whether the destination address [dstAddr] is in the routing
  /// table.
  ///
  /// Returns true if it is in the routing table, otherwise false.
  bool containsDest(String? dstAddr) {
    return _routingTable.containsKey(dstAddr);
  }

  /// Checks whether the next hop address [nextAddr] is in the routing table.
  ///
  /// Returns true if it is in the routing table, otherwise false.
  bool containsNext(String? nextAddr) {
    return _nextDestMapping.containsKey(nextAddr);
  }

  /// Gets the destination address from the next hop address [nextAddr].
  ///
  /// Returns the destination address.
  String? getDestFromNext(String nextAddr) {
    return _nextDestMapping[nextAddr];
  }

  /// Gets a routing table entry associated to the destination address
  /// [dstAddr].
  ///
  /// Returns [EntryRoutingTable] object associated to the destination address.
  EntryRoutingTable? getDestination(String? dstAddr) {
    return _routingTable[dstAddr];
  }

  /// Gets the precursors of a node of destination address [dstAddr].
  ///
  /// Returns a [List] of [String] representing the precursors list.
  List<String?> getPrecursorsFromDest(String? dstAddr) {
    var entry = _routingTable[dstAddr];
    if (entry != null) {
      return entry.precursors;
    }
    return List.empty(growable: true);
  }

  /// Gets the data path from the address [addr].
  ///
  /// Returns an [int] representing the last time the data has been transmitted.
  int getDataPathFromAddress(String? addr) {
    var entry = _routingTable[addr];
    if (entry != null) {
      return entry.getActivesDataPath(addr!);
    }

    return 0;
  }
}
