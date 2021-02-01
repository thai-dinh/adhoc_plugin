import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:adhoclibrary/src/datalink/utils/msg_adhoc.dart';
import 'package:adhoclibrary/src/datalink/service/service_server.dart';
import 'package:adhoclibrary/src/datalink/service/service.dart';
import 'package:flutter_p2p/flutter_p2p.dart';


class WifiServer extends ServiceServer {
  P2pSocket _socket;
  List<MessageAdHoc> _messages;
  StreamSubscription<dynamic> _messageStreamSub;
  int _port;

  WifiServer(bool verbose, this._port) : super(verbose, Service.STATE_NONE) {
    this._messages = List.empty(growable: true);
  }

  void listen() async {
    _socket = await FlutterP2p.openHostPort(_port);
    if (_socket == null)
      print('error');

    _messageStreamSub = _socket.inputStream.listen((data) {
      String stringMsg = Utf8Decoder().convert(Uint8List.fromList(data.data));
      MessageAdHoc message = MessageAdHoc.fromJson(json.decode(stringMsg));
      _messages.add(message);
    });

    // Write data to the client using the _socket.write(UInt8List) or `_socket.writeString("Hello")` method

    // accept a connection on the created socket
    await FlutterP2p.acceptPort(_port);
  }

  void stopListening() {
    if (_messageStreamSub != null)
      _messageStreamSub.cancel();
  }
}
