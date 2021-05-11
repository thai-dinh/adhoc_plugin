import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:adhoc_plugin/src/datalink/ble/ble_adhoc_manager.dart';
import 'package:adhoc_plugin/src/datalink/service/adhoc_event.dart';
import 'package:adhoc_plugin/src/datalink/service/constants.dart' as Constants;
import 'package:adhoc_plugin/src/datalink/service/service_server.dart';
import 'package:adhoc_plugin/src/datalink/utils/msg_adhoc.dart';
import 'package:adhoc_plugin/src/datalink/utils/msg_header.dart';
import 'package:adhoc_plugin/src/datalink/utils/utils.dart';
import 'package:flutter/services.dart';


class BleServer extends ServiceServer {
  static const String _chConnectName = 'ad.hoc.lib/ble.connection';
  static const String _chMessageName = 'ad.hoc.lib/ble.message';
  static const EventChannel _chConnect = const EventChannel(_chConnectName);
  static const EventChannel _chMessage = const EventChannel(_chMessageName);

  StreamSubscription<dynamic>? _connectionSub;
  StreamSubscription<dynamic>? _messageSub;

  BleServer(bool verbose) : super(verbose) {
    BleAdHocManager.setVerbose(verbose);
  }

/*-------------------------------Public methods-------------------------------*/

  void listen() {
    if (verbose) log(ServiceServer.TAG, 'Server: listen()');

    BleAdHocManager.openGattServer();

    _connectionSub = _chConnect.receiveBroadcastStream()
      .listen((map) {
        String mac = map['macAddress'] as String;
        String uuid = (Constants.BLUETOOTHLE_UUID + mac.replaceAll(new RegExp(':'), '')).toLowerCase();
        switch (map['state']) {
          case Constants.STATE_CONNECTED:
            addActiveConnection(mac);
            controller.add(AdHocEvent(Constants.CONNECTION_PERFORMED, [mac, uuid, 0]));
            break;

          case Constants.STATE_NONE:
            removeInactiveConnection(mac);
            controller.add(AdHocEvent(Constants.CONNECTION_ABORTED, mac));
            break;
        }
      }, onDone: () => _connectionSub = null,
    );

    _messageSub = _chMessage.receiveBroadcastStream().listen((map) {
      if (verbose) log(ServiceServer.TAG, 'Server: message received');

      Uint8List messageAsListByte = 
        Uint8List.fromList((map['message'] as List<dynamic>).cast<Uint8List>().expand((x) => List<int>.from(x)..removeAt(0)..removeAt(0)).toList());
      String strMessage = Utf8Decoder().convert(messageAsListByte);
      MessageAdHoc message = MessageAdHoc.fromJson(json.decode(strMessage));

      if (message.header!.mac == null || message.header!.mac!.compareTo('') == 0) {
        message.header = Header(
          messageType: message.header!.messageType,
          label: message.header!.label,
          name: message.header!.name,
          address: message.header!.address,
          mac: map['macAddress'],
          deviceType: message.header!.deviceType
        );
      }

      controller.add(AdHocEvent(Constants.MESSAGE_RECEIVED, message));
    }, onDone: () => _messageSub = null);

    state = Constants.STATE_LISTENING;
  }

  @override
  void stopListening() {
    if (verbose) log(ServiceServer.TAG, 'Server: stopListening');

    super.stopListening();
    if (_connectionSub != null)
      _connectionSub!.cancel();
    if (_messageSub != null)
      _messageSub!.cancel();

    BleAdHocManager.closeGattServer();

    state = Constants.STATE_NONE;
  }

  Future<void> cancelConnection(String? mac) async {
    if (verbose) log(ServiceServer.TAG, 'Server: cancelConnection() -> $mac');

    await BleAdHocManager.cancelConnection(mac);
  }

  Future<void> send(MessageAdHoc message, String? mac) async {
    if (verbose) log(ServiceServer.TAG, 'Server: send() -> $mac');

    await BleAdHocManager.gattServerSendMessage(message, mac);
  }
}
