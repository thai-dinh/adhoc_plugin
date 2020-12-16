import 'package:adhoclibrary/src/datalink/exceptions/no_connection.dart';
import 'package:adhoclibrary/src/datalink/message/msg_adhoc.dart';
import 'package:adhoclibrary/src/datalink/service/service.dart';
import 'package:adhoclibrary/src/datalink/service/service_client.dart';
import 'package:adhoclibrary/src/datalink/wifi/wifi_adhoc_device.dart';

import 'package:flutter_p2p/flutter_p2p.dart';

class WifiServiceClient extends ServiceClient {
  WifiAdHocDevice _device;

  WifiServiceClient(this._device, int attempts, int timeOut)
    : super(Service.STATE_NONE, attempts, timeOut);

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
      }
    }
  }

  void cancelConnection() async {
    if (state == Service.STATE_CONNECTED)
      await FlutterP2p.cancelConnect(_device.wifiP2pDevice);
  }

  void sendMessage(MessageAdHoc msg) {

  }

  MessageAdHoc receiveMessage() {

  }
}
