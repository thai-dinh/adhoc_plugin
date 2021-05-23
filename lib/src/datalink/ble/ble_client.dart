import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:adhoc_plugin/src/datalink/ble/ble_adhoc_device.dart';
import 'package:adhoc_plugin/src/datalink/ble/ble_services.dart';
import 'package:adhoc_plugin/src/datalink/exceptions/no_connection.dart';
import 'package:adhoc_plugin/src/datalink/service/adhoc_event.dart';
import 'package:adhoc_plugin/src/datalink/service/constants.dart';
import 'package:adhoc_plugin/src/datalink/service/service_client.dart';
import 'package:adhoc_plugin/src/datalink/utils/msg_adhoc.dart';
import 'package:adhoc_plugin/src/datalink/utils/utils.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';


/// Class defining the client's logic for the Bluetooth LE implementation.
class BleClient extends ServiceClient {
  static int id = 0;

  late BleAdHocDevice _device;
  late FlutterReactiveBle _reactiveBle;
  late Uuid _characteristicUuid;
  late Uuid _serviceUuid;
  late bool _isInitialized;

  /// Creates a [BleClient] object.
  /// 
  /// The debug/verbose mode is set if [verbose] is true.
  /// 
  /// This client service deals with the remote host [_device].
  /// 
  /// Connection attempts to a remote device are done at most [attempts] times. 
  /// A connection attempt waiting time is set to [timeOut] ms.
  BleClient(
    bool verbose, this._device, int attempts, int timeOut
  ) : super(
    verbose, attempts, timeOut
  ) {
    this._reactiveBle = FlutterReactiveBle();
    this._characteristicUuid = Uuid.parse(CHARACTERISTIC_UUID);
    this._serviceUuid = Uuid.parse(SERVICE_UUID);
    this._isInitialized = false;
  }

/*-------------------------------Public methods-------------------------------*/

  /// Starts the listening process for ad hoc events.
  /// 
  /// In this case, an ad hoc event is a message received from the remote host.
  @override
  void listen() {
    // Get the characteristic of the remote host GATT server
    final qChar = QualifiedCharacteristic(
      serviceId: _serviceUuid,
      characteristicId: _characteristicUuid,
      deviceId: _device.mac!
    );

    List<int> buffer = List.empty(growable: true);

    // Listen to the changes of the characteristic
    _reactiveBle.subscribeToCharacteristic(qChar).listen((chunk) {
      // Recover the flag value
      int flag = chunk[0];
      // Add chunk to buffer
      buffer.addAll(chunk.sublist(MESSAGE_FRAG));

      // End of fragmentation
      if (flag == MESSAGE_END) {
        // Reconstruct the message
        String strMessage = Utf8Decoder().convert(Uint8List.fromList(buffer));
        MessageAdHoc msg = MessageAdHoc.fromJson(json.decode(strMessage));
        // Reset buffer
        buffer.clear();

        if (verbose)
          log(ServiceClient.TAG, 'Client: message received from ${_device.mac}');

        // Notify upper layer of a message received
        controller.add(AdHocEvent(MESSAGE_RECEIVED, msg));
      }
    });

    // Listen to event from the platform-specific side for pairing event
    BleServices.platformEventStream.listen((map) async {
      if (map['type'] == ANDROID_BOND) {
        String mac = map['mac'] as String;
        bool state = map['state'] as bool;

        // If pairing request has succeded, then proceed with the connection
        if (mac == _device.mac!)
          await _initEnvironment();

        // Notify upper layer of bond state with a remote device
        controller.add(AdHocEvent(ANDROID_BOND, [mac, state]));
      }
    });
  }


  /// Stops the listening process for ad hoc events.
  @override
  void stopListening() {
    super.stopListening();
  }


  /// Initiates a connection with the remote device.
  @override
  Future<void> connect() async {
    await _connect(attempts, Duration(milliseconds: backOffTime));
  }


  /// Cancels the connection with the remote device.
  @override
  void disconnect() {
    this.stopListening();
    // Abort connection with the remote host
    BleServices.cancelConnection(_device.mac!);
    // Notify upper layer of a connection aborted
    controller.add(AdHocEvent(CONNECTION_ABORTED, _device.mac!));
  }


  /// Sends a [message] to the remote device.
  @override
  Future<void> send(MessageAdHoc message) async {
    if (verbose) 
      log(ServiceClient.TAG, 'Client: sendMessage() -> ${_device.mac}');

    if (state == STATE_NONE)
      throw NoConnectionException('No remote connection');

    // Get the characteristic of the remote host GATT server
    final characteristic = QualifiedCharacteristic(
      serviceId: _serviceUuid,
      characteristicId: _characteristicUuid,
      deviceId: _device.mac!
    );

    // Convert the MessageAdHoc into bytes
    Uint8List msg = Utf8Encoder().convert(json.encode(message.toJson()));
    int _id = id++ % UINT8_SIZE, mtu = _device.mtu, i = 0, flag, end;

    /* Fragment the message bytes into smaller chunk of bytes */

    // First byte indicates the message ID and second byte the flag value
    // The flag value '0' determines the end of the fragmentation
    if (i + mtu >= msg.length) {
      flag = MESSAGE_END;
      end = msg.length;
    } else {
      flag = MESSAGE_FRAG;
      end = i + mtu;
    }

    do {
      List<int> _chunk = [_id, flag] + List.from(msg.getRange(i, end));
      await _reactiveBle.writeCharacteristicWithoutResponse(
        characteristic, value: _chunk
      );

      Future.delayed(Duration(microseconds: UINT8_SIZE));

      flag = MESSAGE_FRAG;
      i += mtu;

      if (i + mtu >= msg.length) {
        flag = MESSAGE_END;
        end = msg.length;
      } else {
        end = i + mtu;
      }
    } while (i < msg.length);
  }

/*------------------------------Private methods-------------------------------*/
  
  /// Requests the max MTU size used for the connection with the remote device.
  Future<void> _requestMaxMTU() async {
    _device.mtu = await _reactiveBle.requestMtu(
      deviceId: _device.mac!, 
      mtu: MAX_MTU
    );
  }


  /// Initiates a connection attempts with [attempts] times and with a [delay]
  /// (ms) between each try.
  Future<void> _connect(int attempts, Duration delay) async {
    try {
      await _connectionAttempt();
    } on NoConnectionException {
      if (attempts > 0) {
        if (verbose)
          log(ServiceClient.TAG, 'Connection attempt $attempts failed');
        
        await Future.delayed(delay);
        return _connect(attempts - 1, delay * 2);
      }

      rethrow;
    }
  }


  /// Initiates a connection attempt.
  Future<void> _connectionAttempt() async {
    if (verbose) log(ServiceClient.TAG, 'Connect to ${_device.mac}');

    if (state == STATE_NONE || state == STATE_CONNECTING) {
      // Start the connection
      _reactiveBle.connectToDevice(
        id: _device.mac!,
        servicesWithCharacteristicsToDiscover: {},
        connectionTimeout: Duration(seconds: timeOut),
      ).listen((event) async {
        // Listen to the connection state changes
        switch (event.connectionState) {
          case DeviceConnectionState.connected:
            if (verbose)
              log(ServiceClient.TAG, 'Connected to ${_device.mac}');

            // // Check whether it is bonded to the remote host, if not, then
            // // initiate a pairing process
            // if (!(await BleServices.getBondState(_device.mac!))) {
            //   // Pairing request
            //   BleServices.createBond(_device.mac!);
            // } else {
              await _initEnvironment();
            // }
            break;

          case DeviceConnectionState.connecting:
            // Update state of the connection
            state = STATE_CONNECTING;
            break;

          default:
            // Update state of the connection
            state = STATE_NONE;
        }
      });
    }
  }


  /// Initializes the environment upon a successful connection performed.
  Future<void> _initEnvironment() async {
    if (_isInitialized)
      return;

    // Start listening process for ad hoc events (messages)
    listen();

    // Request maximum MTU
    await _requestMaxMTU();

    // Notify upper layer of a successfull connection performed
    controller.add(AdHocEvent(
      CONNECTION_PERFORMED, [_device.mac, _device.address, CLIENT]
    ));

    // Update state of the connection
    state = STATE_CONNECTED;

    _isInitialized = true;
  }
}
