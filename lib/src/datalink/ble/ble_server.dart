import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:adhoclibrary/src/datalink/ble/ble_adhoc_manager.dart';
import 'package:adhoclibrary/src/datalink/service/service_server.dart';
import 'package:adhoclibrary/src/datalink/service/service.dart';
import 'package:adhoclibrary/src/datalink/utils/msg_adhoc.dart';
import 'package:adhoclibrary/src/datalink/utils/utils.dart';
import 'package:flutter/services.dart';


class BleServer extends ServiceServer {
  static const String _channelName = 'ad.hoc.lib/ble.message';
  static const EventChannel _channel = const EventChannel(_channelName);

  StreamSubscription<MessageAdHoc> _msgStreamSub;

  BleServer(bool verbose) : super(verbose, Service.STATE_NONE) {
    BleAdHocManager.setVerbose(verbose);
  }

/*-------------------------------Public methods-------------------------------*/

  void listen(
    void onMessage(MessageAdHoc message), void onError(dynamic error),
  ) {
    if (v) Utils.log(ServiceServer.TAG, 'Server: listen()');

    BleAdHocManager.openGattServer();
    _msgStreamSub = _messageStream().listen(onMessage, onError: onError);

    state = Service.STATE_LISTENING;
  }

  void stopListening() {
    if (v) Utils.log(ServiceServer.TAG, 'Server: stopListening');

    if (_msgStreamSub != null)
      _msgStreamSub.cancel();

    BleAdHocManager.closeGattServer();
    state = Service.STATE_NONE;
  }

  void send(MessageAdHoc message, String address) {
    if (v) Utils.log(ServiceServer.TAG, 'Server: send()');

    BleAdHocManager.serverSendMessage(message, address);
  }

/*------------------------------Private methods-------------------------------*/

  Stream<MessageAdHoc> _messageStream() async* {
    await for (List<dynamic> data in _channel.receiveBroadcastStream()) {
      List<Uint8List> listByte = data.cast<Uint8List>();
      Uint8List messageAsListByte = Uint8List.fromList(listByte.expand((x) {
        List<int> tmp = new List<int>.from(x);
        tmp.removeAt(0);
        return tmp;
      }).toList());

      String strMessage = Utf8Decoder().convert(messageAsListByte);
      yield MessageAdHoc.fromJson(json.decode(strMessage));
    }
  }
}
