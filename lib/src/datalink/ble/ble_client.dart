import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:adhoc_plugin/src/datalink/ble/ble_adhoc_device.dart';
import 'package:adhoc_plugin/src/datalink/ble/ble_adhoc_manager.dart';
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

  /// Remote device
  BleAdHocDevice _device;
  Stream<dynamic> _bondStream;

  StreamSubscription<List<int>>? _messageSub;
  StreamSubscription<ConnectionStateUpdate>? _connnectionSub;

  late FlutterReactiveBle _reactiveBle;
  late Uuid _characteristicUuid;
  late Uuid _serviceUuid;

  /// Creates a [BleClient] object.
  /// 
  /// The debug/verbose mode is set if [verbose] is true.
  /// 
  /// This client service deals with the remote host [_device].
  /// 
  /// Connection attempts to a remote device are done at most [attempts] times.
  /// 
  /// A connection attempt is said to be a failure if nothing happens after 
  /// [timeOut] ms.
  /// 
  /// The stream [_bondStream] allows this client to check whether it is paired
  /// with the remote device or not.
  BleClient(
    bool verbose, this._device, int attempts, int timeOut, this._bondStream
  ) : super(
    verbose, attempts, timeOut
  ) {
    this._reactiveBle = FlutterReactiveBle();
    this._characteristicUuid = Uuid.parse(CHARACTERISTIC_UUID);
    this._serviceUuid = Uuid.parse(SERVICE_UUID);
  }

/*-------------------------------Public methods-------------------------------*/

  /// Starts the listening process for ad hoc events.
  /// 
  /// In this case, an ad hoc event is a message received from the remote host
  /// [_device].
  @override
  void listen() {
    // Get the qualified characteristic of the remote host GATT server
    final qChar = QualifiedCharacteristic(
      serviceId: _serviceUuid,
      characteristicId: _characteristicUuid,
      deviceId: _device.mac!
    );

    // Listen to the change made to the qualified characteristic
    List<Uint8List> buffer = List.empty(growable: true);
    _messageSub = _reactiveBle.subscribeToCharacteristic(qChar).listen((bytes) {
      buffer.add(Uint8List.fromList(bytes));
      // End of fragmentation
      if (bytes[0] == MESSAGE_END) {
        if (verbose)
          log(ServiceClient.TAG, 'Client: message received: ${_device.mac}');
        // Notify upper layer of a message received
        controller.add(
          AdHocEvent(MESSAGE_RECEIVED, processMessage(buffer))
        );
        // Reset buffer
        buffer.clear();
      }
    }, onDone: () => _messageSub = null);
  }

  /// Stops the listening process for ad hoc events.
  @override
  void stopListening() {
    super.stopListening();

    if (_connnectionSub != null)
      _connnectionSub!.cancel();
    if (_messageSub != null)
      _messageSub!.cancel();
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
    BleAdHocManager.cancelConnection(_device.mac!);
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

    int _id = id++;

    final characteristic = QualifiedCharacteristic(
      serviceId: _serviceUuid,
      characteristicId: _characteristicUuid,
      deviceId: _device.mac!
    );

    Uint8List msg = Utf8Encoder().convert(json.encode(message.toJson())), chunk;
    int mtu = _device.mtu - 5, length = msg.length, start = 0, end = mtu;

    // Begin fragmentation of the message into smaller chunk of bytes
    while (length > mtu) {
      chunk = msg.sublist(start, end);
      List<int> tmp = [1, _id % UINT8_SIZE] + chunk.toList();
      await _reactiveBle.writeCharacteristicWithoutResponse(
        characteristic, value: tmp
      );

      start = end;
      end += mtu;
      length -= mtu;
    }

    chunk = msg.sublist(start, msg.length);
    List<int> tmp = [0, _id % UINT8_SIZE] + chunk.toList();
    await _reactiveBle.writeCharacteristicWithoutResponse(
      characteristic, value: tmp
    );
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
      _connnectionSub = _reactiveBle.connectToDevice(
        id: _device.mac!,
        servicesWithCharacteristicsToDiscover: {},
        connectionTimeout: Duration(seconds: timeOut),
      ).listen((event) async {
        // Listen to the connection state changes
        switch (event.connectionState) {
          case DeviceConnectionState.connected:
            if (verbose)
              log(ServiceClient.TAG, 'Connected to ${_device.mac}');

            // Check whether it is bonded to the remote host, if not, then
            // initiate a pairing process
            if (!(await (BleAdHocManager.getBondState(_device.mac!) as Future<bool>))) {
              _bondStream.listen((event) async {
                if (_device.mac == event['macAddress'])
                  await _connectionInitialization();
              });

              // Pairing request
              BleAdHocManager.createBond(_device.mac!);
            } else {
              await _connectionInitialization();
            }
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
  Future<void> _connectionInitialization() async {
    // Start listening process for ad hoc events (messages)
    listen();

    // Request maximum MTU
    await _requestMaxMTU();

    // Notify upper layer of a successfull connection performed
    controller.add(AdHocEvent(
      CONNECTION_PERFORMED, [_device.mac, _device.address, 1]
    ));

    // Update state of the connection
    state = STATE_CONNECTED;
  }
}
