import 'dart:collection';

import 'package:adhoc_plugin/src/datalink/utils/utils.dart';
import 'package:adhoc_plugin/src/network/aodv/entry_routing_table.dart';
import 'package:adhoc_plugin/src/network/aodv/routing_table.dart';


/// Class helping the 'AodvManager' class by managing broadcast requests and 
/// the routing table.
/// 
/// NOTE: Most of the following source code has been borrowed and adapted from 
/// the original codebase provided by Gaulthier Gain, which can be found at:
/// https://github.com/gaulthiergain/AdHocLib
class AodvHelper {
  static const String TAG = '[AodvHelper]';

  final bool _verbose;

  late int _rreqId;
  late RoutingTable _routingTable;
  late HashSet<String> _entryBroadcast;

  /// Creates a [AodvHelper] object.
  /// 
  /// The debug/verbose mode is set if [_verbose] is true.
  AodvHelper(this._verbose) {
    _rreqId = 1;
    _routingTable = RoutingTable(_verbose);
    _entryBroadcast = HashSet();
  }

/*------------------------------Public methods-------------------------------*/

  /// Adds an entry to the routing table.
  /// 
  /// The entry requires the destination address [destAddress], the next 
  /// neighbor address [next] to reach the destination address, the number of 
  /// hops [hop] between the source and the destination, the sequence number 
  /// [seq], lifetime of the entry [lifetime], and the list that contains the 
  /// precursors of the current node [precursors].
  /// 
  /// Return an [EntryRoutingTable] object, which contains the new entry to the 
  /// routing table. The returned value is null upon add operation failure.
  EntryRoutingTable? addEntryRoutingTable(
    String destAddress, String next, int hop, int seq, int lifetime, 
    List<String> precursors
  ) {
    var entry = EntryRoutingTable(
      destAddress, next, hop, seq, lifetime, precursors
    );

    return _routingTable.addEntry(entry) ? entry : null;
  }


  /// Controls the broadcast requests.
  /// 
  /// The unique identifier is represented by the couple 
  /// <[sourceAddress], [rreqId]> in the set.
  /// 
  /// Returns true if it has been added to the set, otherwise false (already
  /// contained in the set).
  bool addBroadcastId(String sourceAddress, int rreqId) {
    var entry = sourceAddress + rreqId.toString();

    if (!_entryBroadcast.contains(entry)) {
      _entryBroadcast.add(entry);

      if (_verbose) log(TAG, 'Add $entry into broadcast set');
      return true;
    } else {
      return false;
    }
  }


  /// Gets the next neighbor address from the destination address.
  /// 
  /// The destination address is specified by [destAddress].
  /// 
  /// Returns an [EntryRoutingTable] object, which contains the entry associated 
  /// to the destination address. The returned value can be null.
  EntryRoutingTable? getNextfromDest(String destAddress) {
    return _routingTable.getNextFromDest(destAddress);
  }


  /// Checks if a destination address [destAddress] is contained in the routing 
  /// table.
  /// 
  /// Returns true if the destination is contained, otherwise false.
  bool containsDest(String destAddress) {
    return _routingTable.containsDest(destAddress);
  }


  /// Gets the incremented broadcast ID.
  int getIncrementRreqId() {
    return _rreqId += 1;
  }


  /// Gets a routing table entry associated to the destination address.
  /// 
  /// The destination address is specified by [destAddress].
  /// 
  /// Returns an [EntryRoutingTable] object, which contains the entry associated 
  /// to the destination address. The returned value can be null.
  EntryRoutingTable? getDestination(String? destAddress) {
    return _routingTable.getDestination(destAddress);
  }


  /// Removes an entry in the routing table from the destination address
  /// [destAddress].
  void removeEntry(String? destAddress) {
    _routingTable.removeEntry(destAddress);
  }


  /// Gets the size ([int]) of the routing table.
  int sizeRoutingTable() {
    return _routingTable.routingTable.length;
  }


  /// Checks if the next hop address is in the routing table.
  /// 
  /// The next hop address is specified by [nextAddress].
  /// 
  /// Returns true if it is, otherwise false.
  bool containsNext(String nextAddress) {
    return _routingTable.containsNext(nextAddress);
  }


  /// Gets the destination address from the next hop address [nextAddress].
  /// 
  /// The returned value is null if no match is found.
  String? getDestFromNext(String nextAddress) {
    return _routingTable.getDestFromNext(nextAddress);
  }


  /// Gets the routing table as a set.
  /// 
  /// Returns a set of type [MapEntry] with key type as [String] and value type
  /// as [EntryRoutingTable].
  Set<MapEntry<String?, EntryRoutingTable?>> getEntrySet() {
    return _routingTable.routingTable.entries.toSet();
  }


  /// Gets the precursors of a node.
  /// 
  /// The destination address is specified by [destAddress].
  /// 
  /// Returns a list ([List]) of the precursor address ([String]).
  List<String?> getPrecursorsFromDest(String destAddress) {
    return _routingTable.getPrecursorsFromDest(destAddress);
  }


  /// Gets the data path from the destination address.
  /// 
  /// Returns an integer ([int]), which represents the last time that data has 
  /// been transmitted by/to [address].
  int getDataPathFromAddress(String address) {
    return _routingTable.getDataPathFromAddress(address);
  }
}
