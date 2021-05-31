import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'wifi_adhoc_manager.dart';
import '../exceptions/no_connection.dart';
import '../service/adhoc_event.dart';
import '../service/constants.dart';
import '../service/service_client.dart';
import '../utils/msg_adhoc.dart';
import '../utils/utils.dart';


/// Class defining the client's logic for the Wi-Fi Direct implementation.
class WifiClient extends ServiceClient {
  late Socket _socket;
  late String _serverIP;
  late int _port;

  /// Creates a [WifiClient] object.
  /// 
  /// The debug/verbose mode is set if [verbose] is true.
  /// 
  /// The listening port number is set to [_port] and the IP address of the 
  /// server is set to [_serverIP].
  /// 
  /// Connection attempts to a remote device are done at most [attempts] times.
  /// 
  /// A connection attempt is said to be a failure if nothing happens after 
  /// [timeOut] ms.
  WifiClient(
    bool verbose, this._port, this._serverIP, int attempts, int timeOut,
  ) : super(verbose, attempts, timeOut);

/*-------------------------------Public methods-------------------------------*/

  /// Starts the listening process for ad hoc events.
  /// 
  /// In this case, an ad hoc event is a message received from server.
  @override
  void listen() {
    // Initialize a buffer
    StringBuffer buffer = StringBuffer();
    // Listen to messages sent by the server
    _socket.listen(
      (data) {
        if (verbose)
          log(ServiceClient.TAG, 'bytes received from $_serverIP:${_socket.port}');

        // Convert bytes to string
        String msg = Utf8Decoder().convert(data);

        if (msg[0].compareTo('{') == 0 && msg[msg.length-1].compareTo('}') == 0) {
          for (MessageAdHoc _msg in splitMessages(msg)) {
            controller.add(AdHocEvent(MESSAGE_RECEIVED, _msg));
            if (verbose) {
              log(ServiceClient.TAG, 
                'received message from $_serverIP:${_socket.port}'
              );
            }
          }
        } else if (msg[msg.length-1].compareTo('}') == 0) {
          buffer.write(msg);
          for (MessageAdHoc _msg in splitMessages(buffer.toString())) {
            controller.add(AdHocEvent(MESSAGE_RECEIVED, _msg));
            if (verbose) {
              log(ServiceClient.TAG, 
                'received message from $_serverIP:${_socket.port}'
              );
            }
          }
          buffer.clear();
        } else {
          buffer.write(msg);
        }
      },
      onError: (error) {
        // Notify the upper layer of an connection exception
        controller.add(AdHocEvent(CONNECTION_EXCEPTION, error));
      },
      onDone: () {
        // Notify the upper layer of an connection aborted
        controller.add(AdHocEvent(CONNECTION_ABORTED, _serverIP));
        // Stop the listening process for ad hoc events.
        this.stopListening();
      }
    );
  }


  /// Stops the listening process for ad hoc events.
  @override
  void stopListening() {
    super.stopListening();
    _socket.destroy();
    _socket.close();
  }


  /// Initiates a connection with the remote device.
  @override
  Future<void> connect() async {
    await _connect(attempts, Duration(milliseconds: backOffTime));
  }


  /// Cancels the connection with the remote device.
  @override
  Future<void> disconnect() async {
    // Notify upper layer of a connection aborted
    controller.add(AdHocEvent(CONNECTION_ABORTED, _serverIP));
    // Leave Wi-Fi Direct group
    await WifiAdHocManager.removeGroup();
    this.stopListening();
  }


  /// Sends a [message] to the remote device.
  @override
  void send(MessageAdHoc message) async {
    if (verbose) log(ServiceClient.TAG, 'send() to $_serverIP:$_port');
    _socket.write(json.encode(message.toJson()));
  }

/*------------------------------Private methods-------------------------------*/

  /// Initiates a connection attempts with [attempts] times and with a [delay]
  /// (ms) between each try.
  Future<void> _connect(int attempts, Duration delay) async {
    try {
      await _connectionAttempt();
    } catch (exception) {
      if (attempts > 0) {
        if (verbose) {
          log(
            ServiceClient.TAG, 
            'Connection attempt failed (${attempts - 1} remaining)'
          );
        }

        await Future.delayed(delay);
        return _connect(attempts - 1, delay * 2);
      } else {
        // Notify upper layer of a failed connection attempts
        controller.add(AdHocEvent(CONNECTION_FAILED, _serverIP));
      }
    }
  }


  /// Initiates a connection attempt.
  /// 
  /// Throws a [NoConnectionException] exception if a connection cannot be
  /// established with the remote device.
  Future<void> _connectionAttempt() async {
    if (verbose) log(ServiceClient.TAG, 'Connect to $_serverIP : $_port');

    if (state == STATE_NONE || state == STATE_CONNECTING) {
      // Update state of the connection
      state = STATE_CONNECTING;

      try {
        // Start the connection
        _socket = await Socket.connect(
          _serverIP, _port, timeout: Duration(milliseconds: timeOut)
        );
      } on SocketException {
        state = STATE_NONE;

        throw NoConnectionException('Unable to connect to $_serverIP');
      }

      // Start the listening process for ad hoc events. In this case, ad hoc
      // events are messages received.
      listen();

      // Notify upper layer of a successful connection performed
      controller.add(AdHocEvent(CONNECTION_PERFORMED, _serverIP));

      if (verbose) log(ServiceClient.TAG, 'Connected to $_serverIP:$_port');

      // Update state of the connection 
      state = STATE_CONNECTED;
    }
  }
}
