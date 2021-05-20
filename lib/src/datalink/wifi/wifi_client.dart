import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:adhoc_plugin/src/datalink/service/adhoc_event.dart';
import 'package:adhoc_plugin/src/datalink/service/constants.dart';
import 'package:adhoc_plugin/src/datalink/utils/msg_adhoc.dart';
import 'package:adhoc_plugin/src/datalink/service/service_client.dart';
import 'package:adhoc_plugin/src/datalink/utils/utils.dart';
import 'package:adhoc_plugin/src/datalink/wifi/wifi_p2p.dart';


/// Class defining the client's logic for the Wi-Fi Direct implementation.
class WifiClient extends ServiceClient {
  late Socket _socket;
  late String _serverIP;
  late int _port;

  WifiClient(
    bool verbose, this._port, this._serverIP, int attempts, int timeOut,
  ) : super(verbose, attempts, timeOut);

/*-------------------------------Public methods-------------------------------*/

  void listen() {
    StringBuffer buffer = StringBuffer();

    _socket.listen(
      (data) {
        if (verbose) log(ServiceClient.TAG, 'received message from $_serverIP:${_socket.port}');

        String msg = Utf8Decoder().convert(data);
        if (msg[0].compareTo('{') == 0 && msg[msg.length-1].compareTo('}') == 0) {
          for (MessageAdHoc _msg in splitMessages(msg))
            controller.add(AdHocEvent(MESSAGE_RECEIVED, _msg));
        } else if (msg[msg.length-1].compareTo('}') == 0) {
          buffer.write(msg);
          for (MessageAdHoc _msg in splitMessages(buffer.toString()))
            controller.add(AdHocEvent(MESSAGE_RECEIVED, _msg));
          buffer.clear();
        } else {
          buffer.write(msg);
        }
      },
      onError: (error) {
        controller.add(AdHocEvent(CONNECTION_EXCEPTION, error));
      },
      onDone: () {
        controller.add(AdHocEvent(CONNECTION_ABORTED, _serverIP));
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
    controller.add(AdHocEvent(CONNECTION_ABORTED, _serverIP));
  }

  void send(MessageAdHoc message) async {
    if (verbose) log(ServiceClient.TAG, 'send() to $_serverIP:$_port');

    _socket.write(json.encode(message.toJson()));
  }

/*------------------------------Private methods-------------------------------*/

  Future<void> _connect(int? attempts, Duration delay) async {
    try {
      await _connectionAttempt();
    } on SocketException {
      if (attempts! > 0) {
        if (verbose)
          log(ServiceClient.TAG, 'Connection attempt $attempts failed');

        await Future.delayed(delay);
        return _connect(attempts - 1, delay * 2);
      }

      rethrow;
    }
  }

  Future<void> _connectionAttempt() async {
    if (verbose) log(ServiceClient.TAG, 'Connect to $_serverIP : $_port');

    if (state == STATE_NONE || state == STATE_CONNECTING) {
      state = STATE_CONNECTING;

      _socket = await Socket.connect(
        _serverIP, _port, timeout: Duration(milliseconds: timeOut)
      );

      listen();
      controller.add(AdHocEvent(CONNECTION_PERFORMED, _serverIP));

      if (verbose) log(ServiceClient.TAG, 'Connected to $_serverIP:$_port');

      state = STATE_CONNECTED;
    }
  }
}
