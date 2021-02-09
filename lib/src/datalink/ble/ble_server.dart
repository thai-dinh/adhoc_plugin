import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:adhoclibrary/src/datalink/ble/ble_adhoc_manager.dart';
import 'package:adhoclibrary/src/datalink/ble/ble_utils.dart';
import 'package:adhoclibrary/src/datalink/service/discovery_event.dart';
import 'package:adhoclibrary/src/datalink/service/service_server.dart';
import 'package:adhoclibrary/src/datalink/service/service.dart';
import 'package:adhoclibrary/src/datalink/utils/msg_adhoc.dart';
import 'package:adhoclibrary/src/datalink/utils/msg_header.dart';
import 'package:adhoclibrary/src/datalink/utils/utils.dart';
import 'package:flutter/services.dart';


class BleServer extends ServiceServer {
  static const String _chConnectName = 'ad.hoc.lib/ble.connection';
  static const String _chMessageName = 'ad.hoc.lib/ble.message';
  static const EventChannel _chConnect = const EventChannel(_chConnectName);
  static const EventChannel _chMessage = const EventChannel(_chMessageName);

  StreamSubscription<dynamic> _conStreamSub;
  StreamSubscription<dynamic> _msgStreamSub;

  BleServer(
    bool verbose,
    void Function(DiscoveryEvent) onEvent,
    void Function(dynamic) onError
  ) : super(verbose, Service.STATE_NONE, onEvent, onError) {
    BleAdHocManager.setVerbose(verbose);
  }

/*-------------------------------Public methods-------------------------------*/

  void listen() {
    if (v) Utils.log(ServiceServer.TAG, 'Server: listen()');

    BleAdHocManager.openGattServer();

    _conStreamSub = _chConnect.receiveBroadcastStream()
      .listen((map) {
        String mac = map['macAddress'] as String;
        switch (map['state']) {
          case BleUtils.STATE_CONNECTED:
            addActiveConnection(mac);
            onEvent(DiscoveryEvent(Service.CONNECTION_PERFORMED, mac));
            break;

          case BleUtils.STATE_DISCONNECTED:
            removeInactiveConnection(mac);
            onEvent(DiscoveryEvent(Service.CONNECTION_CLOSED, mac));
            break;
        }
      },
      onError: onError
    );

    _msgStreamSub = _chMessage.receiveBroadcastStream()
      .listen((map) {
        MessageAdHoc message = _processMessage(map['message']);
        if (message.header.mac.compareTo('') == 0) {
          message.header = Header(
            messageType: message.header.messageType,
            label: message.header.label,
            name: message.header.name,
            address: message.header.address,
            mac: map['macAddress'],
            deviceType: message.header.deviceType
          );
        }

        onEvent(DiscoveryEvent(Service.MESSAGE_RECEIVED, message));
      },
      onError: onError
    );

    state = Service.STATE_LISTENING;
  }

  void stopListening() {
    if (v) Utils.log(ServiceServer.TAG, 'Server: stopListening');

    if (_conStreamSub != null) {
      _conStreamSub.cancel();
      _conStreamSub = null;
    }

    if (_msgStreamSub != null) {
      _msgStreamSub.cancel();
      _msgStreamSub = null;
    }

    BleAdHocManager.closeGattServer();
    state = Service.STATE_NONE;
  }

  void send(MessageAdHoc message, String mac) {
    if (v) Utils.log(ServiceServer.TAG, 'Server: send()');

    BleAdHocManager.gattServerSendMessage(message, mac);
  }

/*------------------------------Private methods-------------------------------*/

  MessageAdHoc _processMessage(List<dynamic> rawMessage) {
    List<Uint8List> listByte = rawMessage.cast<Uint8List>();
    Uint8List messageAsListByte = Uint8List.fromList(listByte.expand(
      (x) {
      List<int> tmp = new List<int>.from(x);
      tmp.removeAt(0);
      return tmp;
      }
    ).toList());

    String strMessage = Utf8Decoder().convert(messageAsListByte);
    return MessageAdHoc.fromJson(json.decode(strMessage));
  }
}
