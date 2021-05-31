import 'dart:io';

import 'package:adhoc_plugin/src/datalink/service/constants.dart';
import 'package:adhoc_plugin/src/datalink/utils/msg_adhoc.dart';
import 'package:adhoc_plugin/src/datalink/utils/msg_header.dart';
import 'package:adhoc_plugin/src/datalink/wifi/wifi_client.dart';
import 'package:adhoc_plugin/src/datalink/wifi/wifi_server.dart';
import 'package:flutter_test/flutter_test.dart';


void main() {
  final bool verbose = true;

  late WifiServer wifiServer;
  late WifiClient wifiClient;

  int port = 4567;
  String serverIP = InternetAddress.loopbackIPv4.address;
  int attempts = 3;
  int timeOut = 1000;
  MessageAdHoc messageAdHoc = MessageAdHoc(
    Header(label: '', messageType: WIFI), 'Hello world!'
  );

  setUp(() async {
    wifiServer = WifiServer(verbose);
    await wifiServer.listen(serverIP, port);

    wifiClient = WifiClient(verbose, port, serverIP, attempts, timeOut);
  });

  tearDown(() {
    wifiServer.stopListening();
  });

  group('WifiClient tests', () {
    test('send(MessageAdHoc message) test', () async {
      await wifiClient.connect();

      wifiClient.send(messageAdHoc);
    });
  });

  group('WifiServer test', () {
    test('send(MessageAdHoc message, String remoteIPAddress) test', () async {
      await wifiClient.connect();

      wifiServer.send(messageAdHoc, serverIP);
      wifiServer.cancelConnection(serverIP);
    });
  });
}
