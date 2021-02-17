import 'dart:collection';

import 'package:adhoclibrary/src/datalink/utils/utils.dart';
import 'package:adhoclibrary/src/network/aodv/entry_routing_table.dart';


class RoutingTable {
  static const String TAG = "[_RoutingTable]";

  final bool verbose;

  HashMap<String, EntryRoutingTable> _routingTable;
  HashMap<String, String> _nextDestMapping;

  RoutingTable(this.verbose) {
    this._routingTable = HashMap();
    this._nextDestMapping = HashMap();
  }

/*-------------------------------Public methods-------------------------------*/

  bool addEntry(EntryRoutingTable entry) {
    if (!_routingTable.containsKey(entry.destIpAddress)) {
      if (verbose) log(TAG, "Add new entry in the RIB " + entry.destIpAddress);
      _routingTable.putIfAbsent(entry.destIpAddress, () => entry);
      _nextDestMapping.putIfAbsent(entry.next, () => entry.destIpAddress);
      return true;
    }

    EntryRoutingTable existingEntry = _routingTable[entry.destIpAddress];

    if (existingEntry.hop >= entry.hop) {
      _routingTable.putIfAbsent(entry.destIpAddress, () => entry);
      _nextDestMapping.putIfAbsent(entry.next, () => entry.destIpAddress);

      if (verbose) {
        log(TAG, "Entry: " + existingEntry.destIpAddress
              + " hops: " + existingEntry.hop.toString()
              + " is replaced by " + entry.destIpAddress
              + " hops: " + entry.hop.toString());
      }

      return true;
    }

    if (verbose) {
      log(TAG, "Entry: " + existingEntry.destIpAddress
            + " hops: " + existingEntry.hop.toString()
            + " is NOT replaced by " + entry.destIpAddress
            + " hops: " + entry.hop.toString());
    }

    return false;
  }

  void removeEntry(String destAddress) {
    _routingTable.remove(destAddress);
  }

  EntryRoutingTable getNextFromDest(String destAddress) {
    return _routingTable[destAddress];
  }

  bool containsDest(String destAddress) {
    return _routingTable.containsKey(destAddress);
  }

  bool containsNext(String nextAddress) {
    return _nextDestMapping.containsKey(nextAddress);
  }

  String getDestFromNext(String nextAddress) {
    return _nextDestMapping[nextAddress];
  }

  HashMap<String, EntryRoutingTable> getRoutingTable() {
    return _routingTable;
  }

  EntryRoutingTable getDestination(String destIpAddress) {
    return _routingTable[destIpAddress];
  }

  List<String> getPrecursorsFromDest(String destAddress) {
    EntryRoutingTable entry = _routingTable[destAddress];
    if (entry != null)
        return entry.precursors;
    return null;
  }

  int getDataPathFromAddress(String address) {
    EntryRoutingTable entry = _routingTable[address];
    if (entry != null) {
        return entry.getActivesDataPath(address);
    }

    return 0;
  }
}
