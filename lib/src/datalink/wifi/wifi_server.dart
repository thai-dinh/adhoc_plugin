import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:adhoclibrary/src/datalink/utils/msg_adhoc.dart';
import 'package:adhoclibrary/src/datalink/service/service_msg_listener.dart';
import 'package:adhoclibrary/src/datalink/service/service_server.dart';
import 'package:adhoclibrary/src/datalink/service/service.dart';
import 'package:adhoclibrary/src/datalink/utils/utils.dart';
import 'package:flutter_p2p/flutter_p2p.dart';


class WifiServer extends ServiceServer {
  StreamSubscription<dynamic> _messageStreamSub;
  P2pSocket _socket;

  WifiServer(bool verbose, ServiceMessageListener serviceMessageListener) 
    : super(verbose, Service.STATE_NONE, serviceMessageListener);

/*-------------------------------Public methods-------------------------------*/

  void send(MessageAdHoc message, String address) {
    // Write data to the client using the _socket.write(UInt8List) or `_socket.writeString("Hello")` method
  }

  void listen([int serverPort]) async {
    if (v) Utils.log(ServiceServer.TAG, 'Server: listening');

    _socket = await FlutterP2p.openHostPort(serverPort);

    _messageStreamSub = _socket.inputStream.listen((data) {
      String stringMsg = Utf8Decoder().convert(Uint8List.fromList(data.data));
      MessageAdHoc message = MessageAdHoc.fromJson(json.decode(stringMsg));
      serviceMessageListener.onMessageReceived(message);
    });

    await FlutterP2p.acceptPort(serverPort);
  }

  void stopListening() {
    if (v) Utils.log(ServiceServer.TAG, 'Server: stop listening');

    if (_messageStreamSub != null)
      _messageStreamSub.cancel();
  }
}
