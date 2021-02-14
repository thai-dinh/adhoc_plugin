import 'dart:async';
import 'dart:convert';

import 'package:adhoclibrary/adhoclibrary.dart';
import 'package:adhoclibrary/src/datalink/service/discovery_event.dart';
import 'package:adhoclibrary/src/datalink/service/service_server.dart';
import 'package:adhoclibrary/src/datalink/service/service.dart';
import 'package:adhoclibrary/src/datalink/utils/msg_adhoc.dart';
import 'package:adhoclibrary/src/datalink/utils/utils.dart';
import 'package:adhoclibrary/src/datalink/wifi/wifi_adhoc_manager.dart';
import 'package:flutter_wifi_p2p/flutter_wifi_p2p.dart';
import 'package:meta/meta.dart';


class WifiServer extends ServiceServer {
  P2pServerSocket _serverSocket;

  WifiServer(
    bool verbose,
    void Function(DiscoveryEvent) onEvent,
    void Function(dynamic) onError
  ) : super(verbose, Service.STATE_NONE, onEvent, onError) {
    WifiAdHocManager.setVerbose(verbose);
  }

/*-------------------------------Public methods-------------------------------*/

  void listen({@required String hostIp, @required int serverPort}) async {
    if (v) Utils.log(ServiceServer.TAG, 'Server: listen()');

    _serverSocket = P2pServerSocket(hostIp, serverPort);

    await _serverSocket.openServer();

    _serverSocket.listen((data) {
      String strMessage = Utf8Decoder().convert(data);
      MessageAdHoc message = MessageAdHoc.fromJson(json.decode(strMessage));
      onEvent(DiscoveryEvent(Service.MESSAGE_RECEIVED, message));
    });

    state = Service.STATE_LISTENING;
  }

  Future<void> stopListening() async {
    if (v) Utils.log(ServiceServer.TAG, 'Server: stopListening()');

    await _serverSocket.close();

    state = Service.STATE_NONE;
  }

  Future<void> send(MessageAdHoc message, String remoteAddress) async {
    if (v) Utils.log(ServiceServer.TAG, 'Server: send()');

    _serverSocket.write(
      json.encode(message.toJson()), remoteAddress: remoteAddress
    );
  }

  Future<void> cancelConnection(String remoteAddress) async {
    await _serverSocket.closeSocket(remoteAddress); 
  }
}
