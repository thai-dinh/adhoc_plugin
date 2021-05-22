import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:adhoc_plugin/src/datalink/ble/ble_services.dart';
import 'package:adhoc_plugin/src/datalink/service/adhoc_event.dart';
import 'package:adhoc_plugin/src/datalink/service/constants.dart';
import 'package:adhoc_plugin/src/datalink/service/service_server.dart';
import 'package:adhoc_plugin/src/datalink/utils/msg_adhoc.dart';
import 'package:adhoc_plugin/src/datalink/utils/msg_header.dart';
import 'package:adhoc_plugin/src/datalink/utils/utils.dart';


/// Class defining the server's logic for the Bluetooth Low Energy 
/// implementation.
class BleServer extends ServiceServer {
  /// Creates a [BleServer] object.
  /// 
  /// The debug/verbose mode is set if [verbose] is true.
  BleServer(bool verbose) : super(verbose);

/*-------------------------------Public methods-------------------------------*/

  /// Starts the listening process for ad hoc events.
  /// 
  /// In this case, an ad hoc event can be a message received from a remote 
  /// host, or a connection establishment notification with a remote host.
  @override
  void listen() {
    if (verbose) log(ServiceServer.TAG, 'Server: listen()');

    // Open the GATT server of the platform-specific side
    BleServices.openGATTServer();

    BleServices.platformEventStream.listen((map) async {
      switch (map['type']) {
        // case ANDROID_BOND:
        //   String mac = map['mac'] as String;
        //   bool state = map['state'] as bool;

        //   // Notify upper layer of bond state with a remote device
        //   controller.add(AdHocEvent(ANDROID_BOND, [mac, state]));
        //   break;

        case ANDROID_CONNECTION:
          String mac = map['mac'] as String;
          bool state = map['state'] as bool;
          String uuid = mac.replaceAll(new RegExp(':'), '').toLowerCase();
          uuid = BLUETOOTHLE_UUID + uuid;

          if (state) {
            addActiveConnection(mac);

            // Notify upper layer of a connection performed
            controller.add(AdHocEvent(CONNECTION_PERFORMED, [mac, uuid, 0]));
          } else {
            removeInactiveConnection(mac);

            // Notify upper layer of a connection aborted
            controller.add(AdHocEvent(CONNECTION_ABORTED, mac));
          }
          break;

        case ANDROID_DATA:
          Uint8List bytes = Uint8List.fromList((map['message'] as List<dynamic>).cast<Uint8List>().expand((x) => List<int>.from(x)..removeAt(0)..removeAt(0)).toList());
          MessageAdHoc message = MessageAdHoc.fromJson(json.decode(Utf8Decoder().convert(bytes)));

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
          controller.add(AdHocEvent(MESSAGE_RECEIVED, message));
          break;

        default:
      }
    });

    // Update state of the server
    state = STATE_LISTENING;
  }

  /// Stops the listening process for ad hoc events.
  @override
  void stopListening() {
    if (verbose) log(ServiceServer.TAG, 'Server: stopListening');

    super.stopListening();

    // Close GATT server
    BleServices.closeGATTServer();

    // Update state
    state = STATE_NONE;
  }

  /// Sends a [message] to the remote device of MAC address [mac].
  @override
  Future<void> send(MessageAdHoc message, String mac) async {
    if (verbose) log(ServiceServer.TAG, 'Server: send() -> $mac');

    await BleServices.GATTSendMessage(message, mac);
  }

  /// Cancels an active connection with the remote device of MAC address [mac].
  @override
  Future<void> cancelConnection(String mac) async {
    if (verbose) log(ServiceServer.TAG, 'Server: cancelConnection() -> $mac');

    await BleServices.cancelConnection(mac);
  }
}
