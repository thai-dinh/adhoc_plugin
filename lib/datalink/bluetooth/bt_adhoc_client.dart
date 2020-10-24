import 'dart:async';

import 'package:AdHocLibrary/datalink/bluetooth/bt_adhoc_device.dart';
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

  void _connect() async {
    if (state == Service.STATE_NONE || state == Service.STATE_CONNECTING) {
      state = Service.STATE_CONNECTING;

      bool result = await _socket.connect(_secure, _device.uuid);

      if (result) {
        state = Service.STATE_CONNECTED;
      } else {
        state = Service.STATE_NONE;
      }
    }
  }

  Timer timeout() => new Timer(Duration(milliseconds: timeOut), handleTimeout);

  void handleTimeout() async {
    bool isConnected = await _socket.isConnected();
    if (!isConnected) {
      _socket.close();
    }
  }

  void connect() {
    int i = 0;

    do {
      try {
        i++;
        _connect();
      } on Exception catch (error) {
        print(error);
      }

    } while (i < attempts);
  }
}