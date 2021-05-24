import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'ble_services.dart';
import '../service/adhoc_event.dart';
import '../service/constants.dart';
import '../service/service_server.dart';
import '../utils/msg_adhoc.dart';
import '../utils/msg_header.dart';
import '../utils/utils.dart';


/// Class defining the server's logic for the Bluetooth Low Energy 
/// implementation.
class BleServer extends ServiceServer {
  static int id = 0;

  late HashMap<String, int> _mapMacMTU;

  /// Creates a [BleServer] object.
  /// 
  /// The debug/verbose mode is set if [verbose] is true.
  BleServer(bool verbose) : super(verbose) {
    this._mapMacMTU = HashMap();
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
    BleServices.openGATTServer();

    // Listen to event from the platform-specific side for connections 
    // information, and data received.
    BleServices.platformEventStream.listen((map) async {
      switch (map['type']) {
        case ANDROID_CONNECTION:
          String mac = map['mac'] as String;
          bool state = map['state'] as bool;
          String uuid = mac.replaceAll(new RegExp(':'), '').toLowerCase();
          uuid = BLUETOOTHLE_UUID + uuid;

          if (state) {
            addActiveConnection(mac);
            _mapMacMTU.putIfAbsent(mac, () => MIN_MTU);

            // Notify upper layer of a connection performed
            controller.add(AdHocEvent(CONNECTION_PERFORMED, [mac, uuid, SERVER]));
          } else {
            removeInactiveConnection(mac);
            _mapMacMTU.remove(mac);

            // Notify upper layer of a connection aborted
            controller.add(AdHocEvent(CONNECTION_ABORTED, mac));
          }
          break;

        case ANDROID_DATA:
          // Message received as bytes
          Uint8List bytes = Uint8List.fromList(map['data']);
          // Reconstruct the message
          MessageAdHoc message = 
            MessageAdHoc.fromJson(json.decode(Utf8Decoder().convert(bytes)));

          // Update the header of the message
          if (message.header.mac == null || message.header.mac!.compareTo('') == 0) {
            String uuid = 
              map['mac'].replaceAll(new RegExp(':'), '').toLowerCase();
            uuid = BLUETOOTHLE_UUID + uuid;

            message.header = Header(
              messageType: message.header.messageType,
              label: message.header.label,
              name: message.header.name,
              address: uuid,
              mac: map['mac'],
              deviceType: message.header.deviceType
            );
          }

          if (verbose)
            log(ServiceServer.TAG, 'Server: message received from ${map['mac']}');

          // Notify upper layer of message received
          controller.add(AdHocEvent(MESSAGE_RECEIVED, message));
          break;

        case ANDROID_MTU:
          String mac = map['mac'] as String;
          int mtu = map['mtu'] as int;

          // Update the MTU value of the remote node
          _mapMacMTU.update(mac, (value) => mtu, ifAbsent: () => mtu);
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

    BleServices.writeToCharacteristic(
      message, mac, _mapMacMTU[mac] == null ? MIN_MTU : MAX_MTU
    );
  }


  /// Cancels an active connection with the remote device of MAC address [mac].
  @override
  Future<void> cancelConnection(String mac) async {
    if (verbose) log(ServiceServer.TAG, 'Server: cancelConnection() -> $mac');

    await BleServices.cancelConnection(mac);
  }
}
