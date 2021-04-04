import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:adhoc_plugin/src/datalink/ble/ble_adhoc_manager.dart';
import 'package:adhoc_plugin/src/datalink/service/adhoc_event.dart';
import 'package:adhoc_plugin/src/datalink/service/service_server.dart';
import 'package:adhoc_plugin/src/datalink/service/service.dart';
import 'package:adhoc_plugin/src/datalink/utils/identifier.dart';
import 'package:adhoc_plugin/src/datalink/utils/msg_adhoc.dart';
import 'package:adhoc_plugin/src/datalink/utils/msg_header.dart';
import 'package:adhoc_plugin/src/datalink/utils/utils.dart';
import 'package:flutter/services.dart';


class BleServer extends ServiceServer {
  static const String _chConnectName = 'ad.hoc.lib/ble.connection';
  static const String _chMessageName = 'ad.hoc.lib/ble.message';
  static const EventChannel _chConnect = const EventChannel(_chConnectName);
  static const EventChannel _chMessage = const EventChannel(_chMessageName);

  StreamSubscription<dynamic> _conStreamSub;
  StreamSubscription<dynamic> _msgSub;

  BleServer(bool verbose) : super(verbose, Service.STATE_NONE) {
    BleAdHocManager.setVerbose(verbose);
  }

/*-------------------------------Public methods-------------------------------*/

  void listen() {
    if (verbose) log(ServiceServer.TAG, 'Server: listen()');

    BleAdHocManager.openGattServer();

    _conStreamSub = _chConnect.receiveBroadcastStream()
      .listen((map) {
        String mac = map['macAddress'] as String;
        switch (map['state']) {
          case Service.STATE_CONNECTED:
            addActiveConnection(mac);
            controller.add(AdHocEvent(Service.CONNECTION_PERFORMED, mac));
            break;

          case Service.STATE_NONE:
            removeInactiveConnection(mac);
            controller.add(AdHocEvent(Service.CONNECTION_ABORTED, mac));
            break;
        }
      }, onDone: () => _conStreamSub = null,
    );

    _msgSub = _chMessage.receiveBroadcastStream().listen((map) {
      if (verbose) log(ServiceServer.TAG, 'Server: message received');

      Uint8List messageAsListByte = 
        Uint8List.fromList((map['message'] as List<dynamic>).cast<Uint8List>().expand((x) => List<int>.from(x)..removeAt(0)..removeAt(0)).toList());
      String strMessage = Utf8Decoder().convert(messageAsListByte);
      MessageAdHoc message = MessageAdHoc.fromJson(json.decode(strMessage));

      if (message.header.mac == null || message.header.mac.ble.compareTo('') == 0) {
        message.header = Header(
          messageType: message.header.messageType,
          label: message.header.label,
          name: message.header.name,
          address: message.header.address,
          mac: Identifier(ble: map['macAddress']),
          deviceType: message.header.deviceType
        );
      }

      controller.add(AdHocEvent(Service.MESSAGE_RECEIVED, message));
    }, onDone: () => _msgSub = null);

    state = Service.STATE_LISTENING;
  }

  @override
  void stopListening() {
    if (verbose) log(ServiceServer.TAG, 'Server: stopListening');

    super.stopListening();
    if (_conStreamSub != null)
      _conStreamSub.cancel();
    if (_msgSub != null)
      _msgSub.cancel();

    BleAdHocManager.closeGattServer();

    state = Service.STATE_NONE;
  }

  Future<void> cancelConnection(String mac) async {
    if (verbose) log(ServiceServer.TAG, 'Server: cancelConnection() -> $mac');

    await BleAdHocManager.cancelConnection(mac);
  }

  Future<void> send(MessageAdHoc message, String mac) async {
    if (verbose) log(ServiceServer.TAG, 'Server: send() -> $mac');

    await BleAdHocManager.gattServerSendMessage(message, mac);
  }
}
