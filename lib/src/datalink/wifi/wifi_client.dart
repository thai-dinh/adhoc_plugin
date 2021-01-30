import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:adhoclibrary/src/datalink/exceptions/no_connection.dart';
import 'package:adhoclibrary/src/datalink/utils/msg_adhoc.dart';
import 'package:adhoclibrary/src/datalink/service/service.dart';
import 'package:adhoclibrary/src/datalink/service/service_client.dart';

import 'package:flutter_p2p/flutter_p2p.dart';

class WifiClient extends ServiceClient {
  int _port;
  String _remoteAddress;
  P2pSocket _socket;
  List<MessageAdHoc> _messages;
  StreamSubscription<dynamic> _messageStreamSub;

  WifiClient(this._port, this._remoteAddress, int attempts, int timeOut) 
    : super(Service.STATE_NONE, attempts, timeOut) {

    this._messages = List.empty(growable: true);
  }

  void connect() => _connect(attempts, Duration(milliseconds: backOffTime));

  Future<void> _connect(int attempts, Duration delay) async {
    try {
      await _connectionAttempt();
    } on NoConnectionException {
      if (attempts > 0) {
        await Future.delayed(delay);
        return _connect(attempts - 1, delay * 2);
      }

      rethrow;
    }
  }

  Future<void> _connectionAttempt() async {
    if (state == Service.STATE_NONE || state == Service.STATE_CONNECTING) {
      state = Service.STATE_CONNECTING;

      _socket = await FlutterP2p.connectToHost(
        _remoteAddress,
        _port,
        timeout: timeOut,
      );

      if (_socket == null)
        throw NoConnectionException('Unable to connect to $_remoteAddress');
    }
  }

  void disconnect() => FlutterP2p.disconnectFromHost(_port);

  void send(MessageAdHoc message) {
    _socket.write(Utf8Encoder().convert(json.encode(message.toJson())));
  }

  void listen() {
    _messageStreamSub = _socket.inputStream.listen((data) {
      String stringMsg = Utf8Decoder().convert(Uint8List.fromList(data.data));
      MessageAdHoc message = MessageAdHoc.fromJson(json.decode(stringMsg));
      _messages.add(message);
    });
  }

  void stopListening() {
    if (_messageStreamSub != null)
      _messageStreamSub.cancel();
  }
}
