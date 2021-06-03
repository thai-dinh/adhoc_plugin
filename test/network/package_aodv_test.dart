import 'package:adhoc_plugin/src/network/aodv/aodv_helper.dart';
import 'package:adhoc_plugin/src/network/aodv/entry_routing_table.dart';
import 'package:adhoc_plugin/src/network/aodv/routing_table.dart';
import 'package:flutter_test/flutter_test.dart';


void main() {
  late String srcAddr;
  late String dstAddr;
  late String next;
  late int hop;
  late int dstSeqNum;
  late int lifetime;
  late List<String> precursors;
  late EntryRoutingTable entry;

  setUp(() {
    srcAddr = 'srcAddr';
    dstAddr = 'dstAddr';
    next = 'next';
    hop = 42;
    dstSeqNum = 42;
    lifetime = 42;
    precursors = List.empty(growable: true);
    entry = EntryRoutingTable(
      dstAddr, next, hop, dstSeqNum, lifetime, precursors
    );
  });

  group('EntryRoutingTable tests', () {
    test('updateDataPath(String address) test', () {
      entry.updateDataPath(dstAddr);

      expect(
        entry.getActivesDataPath(dstAddr), 
        closeTo(DateTime.now().millisecond, 15)
      );
    });

    test('getActivesDataPath(String address) test', () {
      expect(entry.getActivesDataPath('address'), 0);
    });

    test('updatePrecursors(String senderAddr) test', () {
      entry.updatePrecursors(srcAddr);

      expect(entry.precursors.contains(srcAddr), true);
    });

    test('displayPrecursors()', () {
      final precursors = 'precursors: { address }';
      entry.updatePrecursors('address');

      expect(entry.displayPrecursors(), precursors);
    });
  });

  group('RoutingTable tests', () {
    late RoutingTable table;

    setUp(() {
      table = RoutingTable(false);
    });

    test('addEntry(EntryRoutingTable entry) test', () {
      table.addEntry(entry);

      expect(table.routingTable.containsKey(entry.dstAddr), true);
      expect(table.addEntry(entry), true);
    });

    test('removeEntry(String? dstAddr) test', () {
      table.addEntry(entry);
      table.removeEntry(entry.dstAddr);

      expect(table.routingTable.containsKey(entry.dstAddr), false);
    });

    test('getNextFromDest(String? dstAddr) test', () {
      table.addEntry(entry);

      expect(table.getNextFromDest(dstAddr), entry);
      expect(table.getNextFromDest(next), null);
    });

    test('containsDest(String? dstAddr) test', () {
      table.addEntry(entry);

      expect(table.containsDest(dstAddr), true);
    });

    test('containsNext(String? nextAddr) test', () {
      table.addEntry(entry);

      expect(table.containsNext(next), true);
      expect(table.containsNext(dstAddr), false);
    });

    test('getDestFromNext(String nextAddr) test', () {
      expect(table.getDestFromNext(dstAddr), null);
    });

    test('getDestination(String? dstAddr) test', () {
      table.addEntry(entry);

      expect(table.getDestination(dstAddr), entry);
    });

    test('getPrecursorsFromDest(String? dstAddr) test', () {
      expect(table.getPrecursorsFromDest(dstAddr), List.empty(growable: true));
    });

    test('getDataPathFromAddress(String? addr) test', () {
      expect(table.getDataPathFromAddress(srcAddr), 0);
    });
  });

  group('AodvHelper tests', () {
    late AodvHelper aodvHelper;

    setUp(() {
      aodvHelper = AodvHelper(false);
    });

    test('addEntryRoutingTable(...) test', () {
      var result = aodvHelper.addEntryRoutingTable(
        dstAddr, next, hop, dstSeqNum, lifetime, precursors
      )!;

      expect(result.dstAddr, entry.dstAddr);
    });

    test('addBroadcastId(String sourceAddress, int rreqId) test', () {
      expect(aodvHelper.addBroadcastId(srcAddr, 42), true);
      expect(aodvHelper.addBroadcastId(srcAddr, 42), false);
    });

    test('getNextfromDest(String destAddress) test', () {
      aodvHelper.addEntryRoutingTable(
        dstAddr, next, hop, dstSeqNum, lifetime, precursors
      );

      EntryRoutingTable? result = aodvHelper.getNextfromDest(dstAddr)!;

      expect(result.dstAddr, entry.dstAddr);

      result = aodvHelper.getNextfromDest('WrongAddr');

      expect(result, null);
    });

    test('containsDest(String destAddress) test', () {
      aodvHelper.addEntryRoutingTable(
        dstAddr, next, hop, dstSeqNum, lifetime, precursors
      );

      expect(aodvHelper.containsDest(dstAddr), true);
      expect(aodvHelper.containsDest('test'), false);
    });

    test('getIncrementRreqId() test', () {
      expect(aodvHelper.getIncrementRreqId(), 2);
    });

    test('getDestination(String? destAddress) test', () {
      aodvHelper.addEntryRoutingTable(
        dstAddr, next, hop, dstSeqNum, lifetime, precursors
      );

      var result = aodvHelper.getDestination(dstAddr);

      expect(result!.dstAddr, entry.dstAddr);

      result = aodvHelper.getDestination(next);

      expect(result, null);
    });

    test('sizeRoutingTable() test', () {
      expect(aodvHelper.sizeRoutingTable(), 0);

      aodvHelper.addEntryRoutingTable(
        dstAddr, next, hop, dstSeqNum, lifetime, precursors
      );

      expect(aodvHelper.sizeRoutingTable(), 1);

      aodvHelper.removeEntry(dstAddr);

      expect(aodvHelper.sizeRoutingTable(), 0);
    });

    test('containsNext(String nextAddress) test', () {
      expect(aodvHelper.containsNext(next), false);

      aodvHelper.addEntryRoutingTable(
        dstAddr, next, hop, dstSeqNum, lifetime, precursors
      );

      expect(aodvHelper.containsNext(next), true);
    });

    test('getDestFromNext(String nextAddress) test', () {
      expect(aodvHelper.getDestFromNext(next), null);
    });

    test('getDestination(String? destAddress) test', () {
      expect(aodvHelper.getDestination(dstAddr), null);

      aodvHelper.addEntryRoutingTable(
        dstAddr, next, hop, dstSeqNum, lifetime, precursors
      );

      expect(aodvHelper.getDestination(dstAddr)!.dstAddr, entry.dstAddr);
    });

    test('getPrecursorsFromDest(String destAddress) test', () {
      expect(
        aodvHelper.getPrecursorsFromDest('null'), List.empty(growable: true)
      );
    });

    test('getDataPathFromAddress(String address) test', () {
      expect(aodvHelper.getDataPathFromAddress(dstAddr), 0);
    });
  });
}
