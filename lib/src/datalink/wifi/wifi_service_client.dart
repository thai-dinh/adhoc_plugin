import 'dart:async';
import 'dart:convert';

import 'package:adhoclibrary/src/datalink/exceptions/no_connection.dart';
import 'package:adhoclibrary/src/datalink/message/msg_adhoc.dart';
import 'package:adhoclibrary/src/datalink/service/service.dart';
import 'package:adhoclibrary/src/datalink/service/service_client.dart';
import 'package:adhoclibrary/src/datalink/wifi/wifi_adhoc_device.dart';

import 'package:flutter_p2p/flutter_p2p.dart';

class WifiServiceClient extends ServiceClient {
  WifiAdHocDevice _device;
  List<MessageAdHoc> _messages;
  P2pSocket _hostSocket;
  P2pSocket _clientSocket;
  int _hostPort;
  int _clientPort = 4444;

  WifiServiceClient(this._device, this._hostPort, int attempts, int timeOut)
    : super(Service.STATE_NONE, attempts, timeOut) {

    this._messages = List.empty(growable: true);
  }

  WifiServiceClient.host(this._hostPort, int attempts, int timeOut)
    : super(Service.STATE_NONE, attempts, timeOut) {

    this._messages = List.empty(growable: true);
  }

  void openHostPort() async {
    _hostSocket = await FlutterP2p.openHostPort(_hostPort);

    _hostSocket.inputStream.listen((event) {
      String stringMessage = String.fromCharCodes(event.data);
      MessageAdHoc message = MessageAdHoc.fromJson(json.decode(stringMessage));
      _messages.add(message);
    });

    await FlutterP2p.acceptPort(_hostPort);
  }

  void writeToHost(MessageAdHoc message) {
    _clientSocket.writeString(json.encode(message.toJson()));
  }

  void openClientPort() async {
    _clientSocket = await FlutterP2p.connectToHost(
      _device.macAddress,
      _clientPort,
      timeout: 100000,
    );

    _clientSocket.inputStream.listen((event) {
      String stringMessage = String.fromCharCodes(event.data);
      MessageAdHoc message = MessageAdHoc.fromJson(json.decode(stringMessage));
      _messages.add(message);
    });
  }

  void writeToClient(MessageAdHoc message) {
    _hostSocket.writeString(json.encode(message.toJson()));
  }

  void connect() => _connect(attempts, Duration(milliseconds: backOffTime));

  void _connect(int attempts, Duration delay) async {
    try {
      _connectionAttempt();
    } on NoConnectionException {
      if (attempts > 0) {
        await Future.delayed(delay);
        return _connect(attempts - 1, delay * 2);
      }

      rethrow;
    }
  }

  void _connectionAttempt() async {
    if (state == Service.STATE_NONE || state == Service.STATE_CONNECTING) {
      state = Service.STATE_CONNECTING;
      bool result = await FlutterP2p.connect(_device.wifiP2pDevice);
      if (result == true) {
        state = Service.STATE_CONNECTED;
      } else {
        state = Service.STATE_NONE;
        throw NoConnectionException(
          'Unable to connect to ${_device.ipAddress}'
        );
      }
    }
  }

  void disconnect() async {
    if (state == Service.STATE_CONNECTED)
      await FlutterP2p.cancelConnect(_device.wifiP2pDevice);
  }

  void sendMessage(MessageAdHoc msg) => writeToClient(msg);

  void send(MessageAdHoc msg) {

  }

  void listen() {

  }

  void stopListening() {
    
  }

  MessageAdHoc receiveMessage() {
    if (_messages.length > 0) {
      return _messages.removeAt(0);
    }

    return null;
  }
}
