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


/// Class defining the server's logic for the Bluetooth Low Energy 
/// implementation.
class BleServer extends ServiceServer {
  static const String _chConnectName = 'ad.hoc.lib/ble.connection';
  static const String _chMessageName = 'ad.hoc.lib/ble.message';
  static const EventChannel _chConnect = const EventChannel(_chConnectName);
  static const EventChannel _chMessage = const EventChannel(_chMessageName);

  StreamSubscription<dynamic>? _connectionSub;
  StreamSubscription<dynamic>? _messageSub;

  /// Creates a [BleServer] object.
  /// 
  /// The debug/verbose mode is set if [verbose] is true.
  BleServer(bool verbose) : super(verbose) {
    BleAdHocManager.setVerbose(verbose);
  }

/*-------------------------------Public methods-------------------------------*/

  /// Starts the listening process for ad hoc events.
  /// 
  /// In this case, an ad hoc event can be a message received from a remote 
  /// host, or a connection establishment notification with a remote host.
  @override
  void listen() {
    if (verbose) log(ServiceServer.TAG, 'Server: listen()');

    // Open the GATT server of the platform-specific side
    BleAdHocManager.openGATTServer();

    // Listen to state of connection events to other peers
    _connectionSub = _chConnect.receiveBroadcastStream()
      .listen((map) {
        String mac = map['macAddress'] as String;
        String uuid = (Constants.BLUETOOTHLE_UUID + mac.replaceAll(new RegExp(':'), '')).toLowerCase();
        switch (map['state']) {
          // Connection performed
          case Constants.STATE_CONNECTED:
            addActiveConnection(mac);
            // Notify upper layer of a connection performed
            controller.add(AdHocEvent(Constants.CONNECTION_PERFORMED, [mac, uuid, 0]));
            break;

          // Disconnection performed
          case Constants.STATE_NONE:
            removeInactiveConnection(mac);
            // Notify upper layer of a disconnection performed
            controller.add(AdHocEvent(Constants.CONNECTION_ABORTED, mac));
            break;
        }
      }, onDone: () => _connectionSub = null,
    );

    // Listen to message received from peers
    _messageSub = _chMessage.receiveBroadcastStream().listen((map) {
      if (verbose) log(ServiceServer.TAG, 'Server: message received');

      Uint8List messageAsListByte = 
        Uint8List.fromList((map['message'] as List<dynamic>).cast<Uint8List>().expand((x) => List<int>.from(x)..removeAt(0)..removeAt(0)).toList());
      String strMessage = Utf8Decoder().convert(messageAsListByte);
      MessageAdHoc message = MessageAdHoc.fromJson(json.decode(strMessage));

      if (message.header.mac == null || message.header.mac!.compareTo('') == 0) {
        message.header = Header(
          messageType: message.header.messageType,
          label: message.header.label,
          name: message.header.name,
          address: message.header.address,
          mac: map['macAddress'],
          deviceType: message.header.deviceType
        );
      }

      // Notify upper layer of message received
      controller.add(AdHocEvent(Constants.MESSAGE_RECEIVED, message));
    }, onDone: () => _messageSub = null);

    // Update state of the server
    state = Constants.STATE_LISTENING;
  }

  /// Stops the listening process for ad hoc events.
  @override
  void stopListening() {
    if (verbose) log(ServiceServer.TAG, 'Server: stopListening');

    super.stopListening();
    if (_connectionSub != null)
      _connectionSub!.cancel();
    if (_messageSub != null)
      _messageSub!.cancel();

    BleAdHocManager.closeGATTServer();

    state = Constants.STATE_NONE;
  }

  /// Sends a [message] to the remote device of MAC address [mac].
  @override
  Future<void> send(MessageAdHoc message, String? mac) async {
    if (verbose) log(ServiceServer.TAG, 'Server: send() -> $mac');

    await BleAdHocManager.GATTSendMessage(message, mac!);
  }

  /// Cancels an active connection with the remote device of MAC address [mac].
  @override
  Future<void> cancelConnection(String mac) async {
    if (verbose) log(ServiceServer.TAG, 'Server: cancelConnection() -> $mac');

    await BleAdHocManager.cancelConnection(mac);
  }
}
