import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:adhoc_plugin/src/datalink/service/adhoc_event.dart';
import 'package:adhoc_plugin/src/datalink/service/constants.dart';
import 'package:adhoc_plugin/src/datalink/service/service_server.dart';
import 'package:adhoc_plugin/src/datalink/utils/msg_adhoc.dart';
import 'package:adhoc_plugin/src/datalink/utils/utils.dart';
import 'package:adhoc_plugin/src/datalink/wifi/wifi_adhoc_manager.dart';
import 'package:meta/meta.dart';


class WifiServer extends ServiceServer {
  StreamSubscription<Socket> _listenStreamSub;
  HashMap<String, HashMap<int, String>> _mapNameData;
  HashMap<String, StreamSubscription<Uint8List>> _mapIpStream;
  HashMap<String, Socket> _mapIpSocket;
  HashMap<String, StringBuffer> _mapIpBuffer;
  ServerSocket _serverSocket;

  WifiServer(bool verbose) : super(verbose) {
    WifiAdHocManager.setVerbose(verbose);
    this._mapNameData = HashMap();
    this._mapIpStream = HashMap();
    this._mapIpSocket = HashMap();
    this._mapIpBuffer = HashMap();
  }

/*-------------------------------Public methods-------------------------------*/

  void listen({@required String hostIp, @required int serverPort}) async {
    if (verbose) log(ServiceServer.TAG, 'Server: listen()');

    _serverSocket = await ServerSocket.bind(hostIp, serverPort, shared: true);
  
    _listenStreamSub = _serverSocket.listen(
      (socket) {
        String remoteAddress = socket.remoteAddress.address;
        _mapIpSocket.putIfAbsent(remoteAddress, () => socket);
        _mapIpStream.putIfAbsent(remoteAddress, () => socket.listen(
          (data) async {
            if (verbose) log(ServiceServer.TAG, 'received message from $remoteAddress:${socket.remotePort}');

            _mapNameData.putIfAbsent(remoteAddress, () => HashMap());
            _mapIpBuffer.putIfAbsent(remoteAddress, () => StringBuffer());

            String msg = Utf8Decoder().convert(data);
            if (msg[0].compareTo('{') == 0 && msg[msg.length-1].compareTo('}') == 0) {
              for (MessageAdHoc _msg in splitMessages(msg))
                controller.add(AdHocEvent(MESSAGE_RECEIVED, _msg));
            } else if (msg[msg.length-1].compareTo('}') == 0) {
              _mapIpBuffer[remoteAddress].write(msg);
              for (MessageAdHoc _msg in splitMessages(_mapIpBuffer[remoteAddress].toString()))
                controller.add(AdHocEvent(MESSAGE_RECEIVED, _msg));
              _mapIpBuffer[remoteAddress].clear();
            } else {
              _mapIpBuffer[remoteAddress].write(msg);
            }
          },
          onError: (error) {
            // Error reported below as it is the same instance of 'error' below
            _closeSocket(remoteAddress);
          },
          onDone: () {
            _closeSocket(remoteAddress);
            controller.add(AdHocEvent(CONNECTION_ABORTED, remoteAddress));
          }
        ));

        controller.add(AdHocEvent(CONNECTION_PERFORMED, remoteAddress));
      },
      onDone: () => this.stopListening(),
      onError: (error) => controller.add(AdHocEvent(CONNECTION_EXCEPTION, error))
    );

    state = STATE_LISTENING;
  }

  @override
  void stopListening() {
    if (verbose) log(ServiceServer.TAG, 'stopListening()');

    super.stopListening();
    _mapIpStream.forEach((ip, stream) => stream.cancel());
    _mapIpStream.clear();
    _mapIpSocket.forEach((ipAddress, socket) => socket.destroy());
    _mapIpSocket.clear();

    _listenStreamSub.cancel();
    _serverSocket.close();

    state = STATE_NONE;
  }

  Future<void> send(MessageAdHoc message, String remoteAddress) async {
    if (verbose) log(ServiceServer.TAG, 'send() to $remoteAddress');

    _mapIpSocket[remoteAddress].write(json.encode(message.toJson()));
  }

  Future<void> cancelConnection(String remoteAddress) async {
    if (verbose) log(ServiceServer.TAG, 'cancelConnection() - $remoteAddress');

    _closeSocket(remoteAddress);
    controller.add(AdHocEvent(CONNECTION_ABORTED, remoteAddress));
  }

/*------------------------------Private methods-------------------------------*/

  void _closeSocket(String remoteAddress) {
    _mapIpStream[remoteAddress].cancel();
    _mapIpStream.remove(remoteAddress);
    _mapIpSocket[remoteAddress].close();
    _mapIpSocket.remove(remoteAddress);
  }
}
