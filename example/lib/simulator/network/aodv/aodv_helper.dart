import 'dart:async';
import 'dart:collection';

import 'package:adhoclibrary/adhoclibrary.dart' hide RoutingTable;
import 'package:adhoclibrary_example/simulator/network/aodv/routing_table.dart';


class AodvHelper {
  static const String TAG = '[AodvHelper]';

  RoutingTable _routingTable;
  HashSet<String> _entryBroadcast;
  int _rreqId;

  StreamController<String> _logCtrl;

  AodvHelper(this._logCtrl) {
    this._routingTable = RoutingTable(_logCtrl);
    this._entryBroadcast = HashSet();
    this._rreqId = 1;
  }

  EntryRoutingTable addEntryRoutingTable(
    String destAddress, String next, int hop, int seq, int lifetime, 
    List<String> precursors
  ) {
    EntryRoutingTable entry = EntryRoutingTable(
      destAddress, next, hop, seq, lifetime, precursors
    );

    return _routingTable.addEntry(entry) ? entry : null;
  }

  bool addBroadcastId(String sourceAddress, int rreqId) {
    String entry = sourceAddress + rreqId.toString();
    if (!_entryBroadcast.contains(entry)) {
      _entryBroadcast.add(entry);
      _logCtrl.add('Add $entry into broadcast set');
      return true;
    } else {
      return false;
    }
  }

  EntryRoutingTable getNextfromDest(String destAddress) {
    return _routingTable.getNextFromDest(destAddress);
  }

  bool containsDest(String destAddress) {
    return _routingTable.containsDest(destAddress);
  }

  int getIncrementRreqId() {
    return _rreqId++;
  }

  EntryRoutingTable getDestination(String destAddress) {
    return _routingTable.getDestination(destAddress);
  }

  void removeEntry(String destAddress) {
    _routingTable.removeEntry(destAddress);
  }

  int sizeRoutingTable() {
    return _routingTable.getRoutingTable().length;
  }

  bool containsNext(String nextAddress) {
    return _routingTable.containsNext(nextAddress);
  }

  String getDestFromNext(String nextAddress) {
    return _routingTable.getDestFromNext(nextAddress);
  }

  Set<MapEntry<String, EntryRoutingTable>> getEntrySet() {
    return _routingTable.getRoutingTable().entries.toSet();
  }

  List<String> getPrecursorsFromDest(String destAddress) {
    return _routingTable.getPrecursorsFromDest(destAddress);
  }

  int getDataPathFromAddress(String address) {
    return _routingTable.getDataPathFromAddress(address);
  }
}
