import 'dart:async';

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
  StreamSubscription<ConnectionStateUpdate>? _connectionSub;

  late final BleAdHocDevice _device;
  late FlutterReactiveBle _reactiveBle;
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
    _reactiveBle = FlutterReactiveBle();
    _isInitialized = false;
  }

/*-------------------------------Public methods-------------------------------*/

  /// Starts the listening process for ad hoc events.
  /// 
  /// In this case, an ad hoc event is a message received from the remote host.
  @override
  void listen() {
    // Listen to event from the platform-specific side for pairing event
    BleServices.platformEventStream.listen((map) async {
      if (map['type'] == ANDROID_BOND) {
        var mac = map['mac'] as String;
        var state = map['state'] as bool;

        // If pairing request has succeded, then proceed with the connection
        if (mac == _device.mac.ble) {
          await _initEnvironment();
        }

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
    stopListening();
    // Abort connection with the remote host
    if (_connectionSub != null) {
      _connectionSub!.cancel();
      // Notify upper layer of a connection aborted
      controller.add(AdHocEvent(CONNECTION_ABORTED, _device.mac));
    }
  }


  /// Sends a [message] to the remote device.
  @override
  Future<void> send(MessageAdHoc message) async {
    if (verbose) {
      log(ServiceClient.TAG, 'Client: sendMessage() -> ${_device.mac}');
    }

    if (state == STATE_NONE) {
      throw NoConnectionException('No remote connection');
    }

    BleServices.writeToCharacteristic(message, _device.mac.ble, _device.mtu);
  }

/*------------------------------Private methods-------------------------------*/
  
  /// Initiates a connection attempts with [attempts] times and with a [delay]
  /// (ms) between each try.
  Future<void> _connect(int attempts, Duration delay) async {
    try {
      await _connectionAttempt();
    } on NoConnectionException {
      if (attempts > 0) {
        if (verbose) {
          log(ServiceClient.TAG, 'Connection attempt $attempts failed');
        }

        await Future<void>.delayed(delay);
        return _connect(attempts - 1, delay * 2);
      } else {
        // Notify upper layer of a failed connection attempts
        controller.add(AdHocEvent(CONNECTION_FAILED, _device.mac));
      }
    }
  }


  /// Initiates a connection attempt.
  /// 
  /// Throws a [NoConnectionException] exception if a connection cannot be
  /// established with the remote device.
  Future<void> _connectionAttempt() async {
    if (verbose) log(ServiceClient.TAG, 'Connect to ${_device.mac}');

    if (state == STATE_NONE || state == STATE_CONNECTING) {
      // Start the connection
      _connectionSub = _reactiveBle.connectToDevice(
        id: _device.mac.ble,
        servicesWithCharacteristicsToDiscover: {},
        connectionTimeout: Duration(seconds: timeOut),
      ).listen((event) async {
        // Listen to the connection state changes
        switch (event.connectionState) {
          case DeviceConnectionState.connected:
            if (verbose) {
              log(ServiceClient.TAG, 'Connected to ${_device.mac}');
            }

            // // Check whether it is bonded to the remote host, if not, then
            // // initiate a pairing process
            // if (!(await BleServices.getBondState(_device.mac.ble))) {
            //   // Pairing request
            //   BleServices.createBond(_device.mac.ble);
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
            throw NoConnectionException(
              'Unable to connect to ${_device.address}'
            );
        }
      });
    }
  }


  /// Initializes the environment upon a successful connection performed.
  Future<void> _initEnvironment() async {
    if (_isInitialized) {
      return;
    }

    // Start listening process for ad hoc events (messages)
    listen();

    // Request maximum MTU
    _device.mtu = await _reactiveBle.requestMtu(
      deviceId: _device.mac.ble, 
      mtu: MAX_MTU
    );

    // Notify upper layer of a successful connection performed
    controller.add(AdHocEvent(
      CONNECTION_PERFORMED, [_device.mac.ble, _device.address, CLIENT]
    ));

    // Update state of the connection
    state = STATE_CONNECTED;

    _isInitialized = true;
  }
}
