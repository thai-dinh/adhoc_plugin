import 'dart:async';
import 'dart:core';

import 'package:AdHocLibrary/datalink/bluetooth/bt_adhoc_device.dart';
import 'package:AdHocLibrary/datalink/exceptions/no_connection_exception.dart';
import 'package:AdHocLibrary/datalink/service/service.dart';
import 'package:AdHocLibrary/datalink/service/service_client.dart';
import 'package:AdHocLibrary/datalink/sockets/client_socket_bt.dart';

class BluetoothClient extends ServiceClient {
  final bool _secure;
  AdHocBluetoothSocket _socket;
  BluetoothAdHocDevice _device;

  BluetoothClient(int attempts, int timeOut, this._secure, this._device) 
    : super(attempts, timeOut) {

    this._socket = new AdHocBluetoothSocket(_device.macAddress);
  }

  void _connectionAttempt() async {
    if (state == Service.STATE_NONE || state == Service.STATE_CONNECTING) {
      state = Service.STATE_CONNECTING;

      bool result = await _socket.connect(_secure, _device.uuid);

      state = result ? Service.STATE_CONNECTED : Service.STATE_NONE;

      throw new NoConnectionException();
    }
  }

  void _connect(int attempts, Duration delay) async {
    try {
      _connectionAttempt();
    } on Exception {
      if (attempts > 0) {
        await Future.delayed(delay);
        return _connect(attempts - 1, delay * 2);
      }

      rethrow;
    }
  }

  void connect() => _connect(attempts, Duration(milliseconds: backOffTime));
}