import 'package:adhoc_plugin/src/datalink/utils/identifier.dart';
import 'package:adhoc_plugin/src/datalink/utils/msg_adhoc.dart';
import 'package:adhoc_plugin/src/datalink/utils/msg_header.dart';
import 'package:adhoc_plugin/src/network/datalinkmanager/neighbors.dart';
import 'package:adhoc_plugin/src/network/datalinkmanager/network_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';

import 'package_datalink_test.mocks.dart';


@GenerateMocks([NetworkManager, MessageAdHoc, Header])
void main() {
  group('NetworkManager tests', () {
    late MessageAdHoc send;
    late MessageAdHoc received;
    late NetworkManager networkManager;

    setUp(() {
      send = MockMessageAdHoc();
      networkManager = NetworkManager((msg) async {
        received = msg;
      }, () {});
    });

    test('Sending message through a NetworkManager should send', () {
      networkManager.sendMessage(send);

      expect(received, send);
    });
  });

  group('Neighbors tests', () {
    const label = 'label';

    late Identifier mac;
    late Neighbors neighbors;
    late NetworkManager networkManager;

    setUp(() {
      mac = Identifier();
      neighbors = Neighbors();
      networkManager = MockNetworkManager();
    });

    tearDown(() {
      neighbors.clear();
    });

    test('Getting added neighbor should returned its', () {
      neighbors.addNeighbor(label, mac, networkManager);

      expect(neighbors.getNeighbor(label), networkManager);
      expect(neighbors.getNeighbor(label + 'test'), null);
    });

    test('Removing a neighbor should remove it', () {
      neighbors.addNeighbor(label, mac, networkManager);
      neighbors.remove(label);

      expect(neighbors.getNeighbor(label), null);
    });

    test('Updating a neighbor should update it', () {
      final newMac = Identifier(ble: 'test');

      neighbors.addNeighbor(label, mac, networkManager);
      neighbors.updateNeighbor(label, newMac);

      Map<String, Identifier> labelMac = neighbors.labelMac;

      expect(labelMac[label]!.ble, 'test');
    });

    test(
      'Getting the neighbors list (label/mac) should return the correct list', 
      () {
        neighbors.addNeighbor(label, mac, networkManager);

        Map<String, Identifier> labelMac = neighbors.labelMac;

        expect(labelMac.length, 1);
        expect(labelMac.keys.first, label);
        expect(labelMac.values.first, mac);
      }
    );

    test(
      'Getting the neighbors list (label/network manager) should return the ' +
      'correct list', 
      () {
        neighbors.addNeighbor(label, mac, networkManager);

        Map<String, NetworkManager> neigbors = neighbors.neighbors;

        expect(neigbors.keys.first, label);
        expect(neigbors.values.first, networkManager);
      }
    );
  });
}
