import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../service/adhoc_event.dart';
import '../service/constants.dart';
import '../service/service_server.dart';
import '../utils/msg_adhoc.dart';
import '../utils/utils.dart';


/// Class defining the server's logic for the Wi-Fi Direct implementation.
class WifiServer extends ServiceServer {
  late StreamSubscription<Socket> _connectionSub;
  late HashMap<String, HashMap<int, String>> _mapNameData;
  late HashMap<String, StreamSubscription<Uint8List>> _mapIpStream;
  late HashMap<String, Socket> _mapIpSocket;
  late HashMap<String, StringBuffer> _mapIpBuffer;
  late ServerSocket _serverSocket;

  /// Creates a [WifiServer] object.
  /// 
  /// The debug/verbose mode is set if [verbose] is true.
  WifiServer(bool verbose) : super(verbose) {
    this._mapNameData = HashMap();
    this._mapIpStream = HashMap();
    this._mapIpSocket = HashMap();
    this._mapIpBuffer = HashMap();
  }

/*-------------------------------Public methods-------------------------------*/

  /// Starts the listening process for incoming connections.
  /// 
  /// The socket connects to [hostIP] at port number [serverPort].
  @override
  void listen([String? hostIP, int? serverPort]) async {
    if (verbose) log(ServiceServer.TAG, 'Server: listen()');

    _serverSocket = await ServerSocket.bind(hostIP, serverPort!, shared: true);
  
    _connectionSub = _serverSocket.listen(
      (socket) {
        String remoteIPAddress = socket.remoteAddress.address;
        _mapIpSocket.putIfAbsent(remoteIPAddress, () => socket);
        _mapIpStream.putIfAbsent(remoteIPAddress, () => socket.listen(
          (data) async {
            if (verbose) {
              log(
                ServiceServer.TAG, 
                'bytes received from $remoteIPAddress:${socket.remotePort}'
              );
            }

            _mapNameData.putIfAbsent(remoteIPAddress, () => HashMap());
            _mapIpBuffer.putIfAbsent(remoteIPAddress, () => StringBuffer());

            String msg = Utf8Decoder().convert(data);
            if (msg[0].compareTo('{') == 0 && msg[msg.length-1].compareTo('}') == 0) {
              for (MessageAdHoc _msg in splitMessages(msg)) {
                controller.add(AdHocEvent(MESSAGE_RECEIVED, _msg));
                if (verbose) {
                  log(ServiceServer.TAG, 
                    'received message from $remoteIPAddress:${socket.remotePort}'
                  );
                }
              }
            } else if (msg[msg.length-1].compareTo('}') == 0) {
              _mapIpBuffer[remoteIPAddress]!.write(msg);
              for (MessageAdHoc _msg in splitMessages(_mapIpBuffer[remoteIPAddress].toString())) {
                controller.add(AdHocEvent(MESSAGE_RECEIVED, _msg));
                if (verbose) {
                  log(ServiceServer.TAG, 
                    'received message from $remoteIPAddress:${socket.remotePort}'
                  );
                }
              }
              _mapIpBuffer[remoteIPAddress]!.clear();
            } else {
              _mapIpBuffer[remoteIPAddress]!.write(msg);
            }
          },
          onError: (error) {
            // Error reported below as it is the same instance of 'error' below
            _closeSocket(remoteIPAddress);
          },
          onDone: () {
            _closeSocket(remoteIPAddress);
            controller.add(AdHocEvent(CONNECTION_ABORTED, remoteIPAddress));
          }
        ));

        controller.add(AdHocEvent(CONNECTION_PERFORMED, remoteIPAddress));
      },
      onDone: () => this.stopListening(),
      onError: (error) => controller.add(AdHocEvent(CONNECTION_EXCEPTION, error))
    );

    state = STATE_LISTENING;
  }


  /// Stops the listening process for incoming connections.
  @override
  void stopListening() {
    if (verbose) log(ServiceServer.TAG, 'stopListening()');

    super.stopListening();
    _mapIpStream.forEach((ip, stream) => stream.cancel());
    _mapIpStream.clear();
    _mapIpSocket.forEach((ipAddress, socket) => socket.destroy());
    _mapIpSocket.clear();

    _connectionSub.cancel();
    _serverSocket.close();

    state = STATE_NONE;
  }


  /// Sends a [message] to the remote device of IP address [remoteIPAddress].
  @override
  Future<void> send(MessageAdHoc message, String? remoteIPAddress) async {
    if (verbose) log(ServiceServer.TAG, 'send() to $remoteIPAddress');

    _mapIpSocket[remoteIPAddress!]!.write(json.encode(message.toJson()));
  }


  /// Cancels an active connection with the remote device of IP address 
  /// [remoteIPAddress].
  @override
  Future<void> cancelConnection(String remoteIPAddress) async {
    if (verbose) log(ServiceServer.TAG, 'cancelConnection() - $remoteIPAddress');

    _closeSocket(remoteIPAddress);
    controller.add(AdHocEvent(CONNECTION_ABORTED, remoteIPAddress));
  }

/*------------------------------Private methods-------------------------------*/

  /// Closes a socket.
  /// 
  /// The socket associated to the IP address [remoteIPAddress] is closed.
  void _closeSocket(String remoteIPAddress) {
    _mapIpStream[remoteIPAddress]!.cancel();
    _mapIpStream.remove(remoteIPAddress);
    _mapIpSocket[remoteIPAddress]!.close();
    _mapIpSocket.remove(remoteIPAddress);
  }
}
