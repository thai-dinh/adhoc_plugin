import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:adhoclibrary/adhoclibrary.dart';
import 'package:adhoclibrary/src/datalink/service/discovery_event.dart';
import 'package:adhoclibrary/src/datalink/service/service_client.dart';
import 'package:adhoclibrary/src/datalink/service/service_server.dart';
import 'package:adhoclibrary/src/datalink/service/service.dart';
import 'package:adhoclibrary/src/datalink/utils/msg_adhoc.dart';
import 'package:adhoclibrary/src/datalink/utils/utils.dart';
import 'package:adhoclibrary/src/datalink/wifi/wifi_adhoc_manager.dart';
import 'package:flutter_p2p/flutter_p2p.dart';


class WifiServer extends ServiceServer {
  StreamSubscription<dynamic> _messageStreamSub;
  P2pSocket _socket;

  WifiServer(
    bool verbose,
    void Function(DiscoveryEvent) onEvent,
    void Function(dynamic) onError
  ) : super(verbose, Service.STATE_NONE, onEvent, onError) {
    WifiAdHocManager.setVerbose(verbose);
  }

/*-------------------------------Public methods-------------------------------*/

  void listen({int serverPort}) async {
    if (v) Utils.log(ServiceServer.TAG, 'Server: listen()');

    _socket = await FlutterP2p.openHostPort(serverPort);

    _messageStreamSub = _socket.inputStream.listen((data) {
      String strMessage = Utf8Decoder().convert(Uint8List.fromList(data.data));
      MessageAdHoc message = MessageAdHoc.fromJson(json.decode(strMessage));
      onEvent(DiscoveryEvent(Service.MESSAGE_RECEIVED, message));
    }, onError: onError);

    state = Service.STATE_LISTENING;

    await FlutterP2p.acceptPort(serverPort);
  }

  void stopListening() {
    if (v) Utils.log(ServiceServer.TAG, 'Server: stopListening()');

    if (_messageStreamSub != null)
      _messageStreamSub.cancel();

    state = Service.STATE_NONE;
  }

  Future<void> send(MessageAdHoc message, String mac) async {
    if (v) Utils.log(ServiceClient.TAG, 'Server: send()');

    await _socket.write(Utf8Encoder().convert(json.encode(message.toJson())));
  }

  void cancelConnection(String mac) {
    
  } 
}
