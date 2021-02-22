import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:adhoclibrary/src/datalink/exceptions/no_connection.dart';
import 'package:adhoclibrary/src/datalink/service/discovery_event.dart';
import 'package:adhoclibrary/src/datalink/utils/msg_adhoc.dart';
import 'package:adhoclibrary/src/datalink/service/service.dart';
import 'package:adhoclibrary/src/datalink/service/service_client.dart';
import 'package:adhoclibrary/src/datalink/utils/utils.dart';
import 'package:flutter_wifi_p2p/flutter_wifi_p2p.dart';


class WifiClient extends ServiceClient {
  StreamSubscription<Uint8List> _listenStreamSub;
  Socket _socket;
  String _serverIp;
  int _port;

  void Function(String) _connectListener;

  WifiClient(
    bool verbose, this._port, this._serverIp, int attempts, int timeOut,
    void Function(DiscoveryEvent) onEvent, void Function(dynamic) onError
  ) : super(
    verbose, Service.STATE_NONE, attempts, timeOut, onEvent, onError
  );

/*------------------------------Getters & Setters-----------------------------*/

  set connectListener(void Function(String) connectListener) {
    this._connectListener = connectListener;
  }

/*-------------------------------Public methods-------------------------------*/

  void listen() {
    if (v) log(ServiceClient.TAG, 'Client: listen()');

    _listenStreamSub = _socket.listen(
      (data) {
        String strMessage = Utf8Decoder().convert(data);
        MessageAdHoc message = MessageAdHoc.fromJson(json.decode(strMessage));
        onEvent(DiscoveryEvent(Service.MESSAGE_RECEIVED, message));
      },
      onError: (error) async {
        try {
          await _socket.done;
        } catch (e) {
          // Error reported below as it is the same instance of 'error'
          await stopListening();
        }

        onEvent(DiscoveryEvent(Service.CONNECTION_EXCEPTION, error));
      },
      onDone: () async {
        await stopListening();
        onEvent(DiscoveryEvent(Service.CONNECTION_CLOSED, _serverIp));
      }
    );
  }

  Future<void> stopListening() async {
    if (v) log(ServiceClient.TAG, 'Client: stopListening()');

    if (_listenStreamSub != null)
      _listenStreamSub.pause();
  }

  Future<void> connect() async {
    await _connect(attempts, Duration(milliseconds: backOffTime));
  }

  Future<void> disconnect() async {
    await stopListening();

    if (_socket != null)
      _socket.destroy();

    await FlutterWifiP2p().removeGroup();
    onEvent(DiscoveryEvent(Service.CONNECTION_CLOSED, _serverIp));
  }

  void send(MessageAdHoc message) {
    if (v) log(ServiceClient.TAG, 'Client: send()');

    _socket.write(json.encode(message.toJson()));
  }

/*------------------------------Private methods-------------------------------*/

  Future<void> _connect(int attempts, Duration delay) async {
    try {
      await _connectionAttempt();
    } on NoConnectionException {
      if (attempts > 0) {
        if (v)
          log(ServiceClient.TAG, 'Connection attempt $attempts failed');

        await Future.delayed(delay);
        return _connect(attempts - 1, delay * 2);
      }

      rethrow;
    }
  }

  Future<void> _connectionAttempt() async {
    if (v) log(ServiceClient.TAG, 'Connect to $_serverIp : $_port');

    if (state == Service.STATE_NONE || state == Service.STATE_CONNECTING) {
      state = Service.STATE_CONNECTING;

      _socket = await Socket.connect(
        _serverIp, _port, timeout: Duration(milliseconds: timeOut)
      );

      onEvent(DiscoveryEvent(Service.CONNECTION_PERFORMED, _serverIp));

      if (_connectListener != null)
        _connectListener(_serverIp);

      if (v) log(ServiceClient.TAG, 'Connected to $_serverIp');

      state = Service.STATE_CONNECTED;
    }
  }
}
