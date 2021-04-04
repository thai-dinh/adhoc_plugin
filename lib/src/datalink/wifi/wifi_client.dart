import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:adhoc_plugin/src/datalink/service/adhoc_event.dart';
import 'package:adhoc_plugin/src/datalink/utils/msg_adhoc.dart';
import 'package:adhoc_plugin/src/datalink/service/service.dart';
import 'package:adhoc_plugin/src/datalink/service/service_client.dart';
import 'package:adhoc_plugin/src/datalink/utils/utils.dart';
import 'package:adhoc_plugin/src/datalink/wifi/wifi_p2p.dart';


class WifiClient extends ServiceClient {
  Socket _socket;
  String _serverIp;
  int _port;

  WifiClient(
    bool verbose, this._port, this._serverIp, int attempts, int timeOut,
  ) : super(
    verbose, Service.STATE_NONE, attempts, timeOut
  );

/*-------------------------------Public methods-------------------------------*/

  void listen() {
    StringBuffer buffer = StringBuffer();

    _socket.listen(
      (data) {
        if (verbose) log(ServiceClient.TAG, 'received message from $_serverIp:${_socket.port}');

        String msg = Utf8Decoder().convert(data);
        if (msg[0].compareTo('{') == 0 && msg[msg.length-1].compareTo('}') == 0) {
          for (MessageAdHoc _msg in splitMessages(msg))
            controller.add(AdHocEvent(Service.MESSAGE_RECEIVED, _msg));
        } else if (msg[msg.length-1].compareTo('}') == 0) {
          buffer.write(msg);
          for (MessageAdHoc _msg in splitMessages(buffer.toString()))
            controller.add(AdHocEvent(Service.MESSAGE_RECEIVED, _msg));
          buffer.clear();
        } else {
          buffer.write(msg);
        }
      },
      onError: (error) {
        controller.add(AdHocEvent(Service.CONNECTION_EXCEPTION, error));
      },
      onDone: () {
        controller.add(AdHocEvent(Service.CONNECTION_ABORTED, _serverIp));
        this.stopListening();
      }
    );
  }

  @override
  void stopListening() {
    super.stopListening();
    _socket.destroy();
    _socket.close();
  }

  Future<void> connect() async {
    await _connect(attempts, Duration(milliseconds: backOffTime));
  }

  Future<void> disconnect() async {
    this.stopListening();
    await WifiP2p().removeGroup();
    controller.add(AdHocEvent(Service.CONNECTION_ABORTED, _serverIp));
  }

  void send(MessageAdHoc message) async {
    if (verbose) log(ServiceClient.TAG, 'send() to $_serverIp:$_port');

    _socket.write(json.encode(message.toJson()));
  }

/*------------------------------Private methods-------------------------------*/

  Future<void> _connect(int attempts, Duration delay) async {
    try {
      await _connectionAttempt();
    } on SocketException {
      if (attempts > 0) {
        if (verbose)
          log(ServiceClient.TAG, 'Connection attempt $attempts failed');

        await Future.delayed(delay);
        return _connect(attempts - 1, delay * 2);
      }

      rethrow;
    }
  }

  Future<void> _connectionAttempt() async {
    if (verbose) log(ServiceClient.TAG, 'Connect to $_serverIp : $_port');

    if (state == Service.STATE_NONE || state == Service.STATE_CONNECTING) {
      state = Service.STATE_CONNECTING;

      _socket = await Socket.connect(
        _serverIp, _port, timeout: Duration(milliseconds: timeOut)
      );

      listen();
      controller.add(AdHocEvent(Service.CONNECTION_PERFORMED, _serverIp));

      if (verbose) log(ServiceClient.TAG, 'Connected to $_serverIp:$_port');

      state = Service.STATE_CONNECTED;
    }
  }
}
