import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:adhoclibrary/src/datalink/exceptions/no_connection.dart';
import 'package:adhoclibrary/src/datalink/service/discovery_event.dart';
import 'package:adhoclibrary/src/datalink/utils/msg_adhoc.dart';
import 'package:adhoclibrary/src/datalink/service/service.dart';
import 'package:adhoclibrary/src/datalink/service/service_client.dart';
import 'package:adhoclibrary/src/datalink/utils/utils.dart';
import 'package:flutter_p2p/flutter_p2p.dart';


class WifiClient extends ServiceClient {
  StreamSubscription<dynamic> _messageStreamSub;
  String _remoteAddress;
  P2pSocket _socket;
  int _port;

  void Function(String) _connectListener;

  WifiClient(
    bool verbose, this._port, this._remoteAddress, int attempts, int timeOut,
    void Function(DiscoveryEvent) onEvent,
    void Function(dynamic) onError
  ) : super(
    verbose, Service.STATE_NONE, attempts, timeOut, onEvent, onError
  );

/*------------------------------Getters & Setters-----------------------------*/

  set connectListener(void Function(String) connectListener) {
    this._connectListener = connectListener;
  }

/*-------------------------------Public methods-------------------------------*/

  void listen() {
    if (v) Utils.log(ServiceClient.TAG, 'Client: listen()');

    _messageStreamSub = _socket.inputStream.listen((data) {
      String strMessage = Utf8Decoder().convert(Uint8List.fromList(data.data));
      MessageAdHoc message = MessageAdHoc.fromJson(json.decode(strMessage));
      if (message.header.messageType == Service.MAC_EXCHANGE_SERVER) {
        onEvent(DiscoveryEvent(Service.MAC_EXCHANGE_SERVER, message));
      } else {
        onEvent(DiscoveryEvent(Service.MESSAGE_RECEIVED, message));
      }
    });
  }

  void stopListening() {
    if (v) Utils.log(ServiceClient.TAG, 'Client: stopListening()');

    if (_messageStreamSub != null)
      _messageStreamSub.cancel();
  }

  void connect() => _connect(attempts, Duration(milliseconds: backOffTime));

  void disconnect() {
    FlutterP2p.disconnectFromHost(_port);

    onEvent(DiscoveryEvent(Service.CONNECTION_CLOSED, _port));
  }

  Future<void> send(MessageAdHoc message) async {
    if (v) Utils.log(ServiceClient.TAG, 'send()');

    await _socket.write(Utf8Encoder().convert(json.encode(message.toJson())));
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
    if (v) Utils.log(ServiceClient.TAG, 'Connect to $_remoteAddress : $_port');

    if (state == Service.STATE_NONE || state == Service.STATE_CONNECTING) {
      state = Service.STATE_CONNECTING;

      _socket = await FlutterP2p.connectToHost(
        _remoteAddress, _port, timeout: timeOut,
      );

      if (_socket == null) {
        state = Service.STATE_NONE;
        throw NoConnectionException('Unable to connect to $_remoteAddress');
      }

      onEvent(DiscoveryEvent(Service.CONNECTION_PERFORMED, _port));

      if (_connectListener != null)
        _connectListener(_remoteAddress);

      if (v) Utils.log(ServiceClient.TAG, 'Connected to $_remoteAddress');

      state = Service.STATE_CONNECTED;
    }
  }
}
