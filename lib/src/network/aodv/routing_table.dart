import 'dart:collection';

import 'package:adhoc_plugin/src/datalink/utils/utils.dart';
import 'package:adhoc_plugin/src/network/aodv/entry_routing_table.dart';


/// Class representing the routing table of the AODV protocol.
class RoutingTable {
  static const String TAG = '[RoutingTable]';

  final bool _verbose;

  late HashMap<String?, String?> _nextDestMapping;
  late HashMap<String?, EntryRoutingTable> _routingTable;

  /// Creates a [RoutingTable] object.
  /// 
  /// The debug/verbose mode is set if [_verbose] is true.
  RoutingTable(this._verbose) {
    this._nextDestMapping = HashMap();
    this._routingTable = HashMap();
  }

/*-------------------------------Public methods-------------------------------*/

  bool addEntry(EntryRoutingTable entry) {
    if (!_routingTable.containsKey(entry.destAddress)) {
      if (_verbose) log(TAG, 'Add new entry in the RIB ${entry.destAddress}');
      _routingTable.putIfAbsent(entry.destAddress, () => entry);
      _nextDestMapping.putIfAbsent(entry.next, () => entry.destAddress);
      return true;
    }

    EntryRoutingTable existingEntry = _routingTable[entry.destAddress]!;

    if (existingEntry.hop >= entry.hop) {
      _routingTable.putIfAbsent(entry.destAddress, () => entry);
      _nextDestMapping.putIfAbsent(entry.next, () => entry.destAddress);

      if (_verbose) {
        log(TAG, 'Entry: ${existingEntry.destAddress}'
              + ' hops: ${existingEntry.hop}'
              + ' is replaced by ${entry.destAddress}'
              + ' hops: ${entry.hop}');
      }

      return true;
    }

    if (_verbose) {
      log(TAG, 'Entry: ${existingEntry.destAddress}'
            + ' hops: ${existingEntry.hop}'
            + ' is NOT replaced by ${entry.destAddress}'
            + ' hops: ${entry.hop}');
    }

    return false;
  }

  void removeEntry(String? destAddress) {
    _routingTable.remove(destAddress);
  }

  EntryRoutingTable? getNextFromDest(String? destAddress) {
    return _routingTable[destAddress];
  }

  bool containsDest(String? destAddress) {
    return _routingTable.containsKey(destAddress);
  }

  bool containsNext(String? nextAddress) {
    return _nextDestMapping.containsKey(nextAddress);
  }

  String? getDestFromNext(String? nextAddress) {
    return _nextDestMapping[nextAddress];
  }

  HashMap<String?, EntryRoutingTable>? getRoutingTable() {
    return _routingTable;
  }

  EntryRoutingTable? getDestination(String? destAddress) {
    return _routingTable[destAddress];
  }

  List<String?> getPrecursorsFromDest(String? destAddress) {
    EntryRoutingTable? entry = _routingTable[destAddress];
    if (entry != null)
        return entry.precursors;
    return List.empty(growable: true);
  }

  int getDataPathFromAddress(String? address) {
    EntryRoutingTable? entry = _routingTable[address];
    if (entry != null)
        return entry.getActivesDataPath(address!);
    return 0;
  }
}
