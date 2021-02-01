import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:adhoclibrary/src/datalink/exceptions/no_connection.dart';
import 'package:adhoclibrary/src/datalink/utils/msg_adhoc.dart';
import 'package:adhoclibrary/src/datalink/service/service.dart';
import 'package:adhoclibrary/src/datalink/service/service_client.dart';
import 'package:adhoclibrary/src/datalink/utils/utils.dart';
import 'package:flutter_p2p/flutter_p2p.dart';


class WifiClient extends ServiceClient {
  int _port;
  String _remoteAddress;
  P2pSocket _socket;
  List<MessageAdHoc> _messages;
  StreamSubscription<dynamic> _messageStreamSub;

  WifiClient(bool verbose, this._port, this._remoteAddress, int attempts, int timeOut) 
    : super(verbose, Service.STATE_NONE, attempts, timeOut) {

    this._messages = List.empty(growable: true);
  }

/*-------------------------------Public methods-------------------------------*/

  void connect() => _connect(attempts, Duration(milliseconds: backOffTime));

  void disconnect() => FlutterP2p.disconnectFromHost(_port);

  void listen() {
    if (v) Utils.log(ServiceClient.TAG, 'listen()');

    _messageStreamSub = _socket.inputStream.listen((data) {
      if (v) Utils.log(ServiceClient.TAG, 'Message received');

      String stringMsg = Utf8Decoder().convert(Uint8List.fromList(data.data));
      MessageAdHoc message = MessageAdHoc.fromJson(json.decode(stringMsg));
      _messages.add(message);
    });
  }

  void stopListening() {
    if (v) Utils.log(ServiceClient.TAG, 'stopListening()');

    if (_messageStreamSub != null)
      _messageStreamSub.cancel();
  }

  void send(MessageAdHoc message) {
    if (v) Utils.log(ServiceClient.TAG, 'send()');

    _socket.write(Utf8Encoder().convert(json.encode(message.toJson())));
  }

/*------------------------------Private methods-------------------------------*/

  Future<void> _connect(int attempts, Duration delay) async {
    try {
      await _connectionAttempt();
    } on NoConnectionException {
      if (attempts > 0) {
        if (v)
          Utils.log(ServiceClient.TAG, 'Connection attempt $attempts failed');

        await Future.delayed(delay);
        return _connect(attempts - 1, delay * 2);
      }

      rethrow;
    }
  }

  Future<void> _connectionAttempt() async {
    if (v) {
      Utils.log(ServiceClient.TAG, 'Connect to $_remoteAddress');
    }

    if (state == Service.STATE_NONE || state == Service.STATE_CONNECTING) {
      state = Service.STATE_CONNECTING;

      _socket = await FlutterP2p.connectToHost(
        _remoteAddress,
        _port,
        timeout: timeOut,
      );

      if (_socket == null)
        throw NoConnectionException('Unable to connect to $_remoteAddress');

      if (v) Utils.log(ServiceClient.TAG, 'Connected to $_remoteAddress');

      state = Service.STATE_CONNECTED;
    }
  }
}
