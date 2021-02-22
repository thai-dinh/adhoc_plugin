import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:adhoclibrary/adhoclibrary.dart';
import 'package:adhoclibrary/src/datalink/service/discovery_event.dart';
import 'package:adhoclibrary/src/datalink/service/service_server.dart';
import 'package:adhoclibrary/src/datalink/service/service.dart';
import 'package:adhoclibrary/src/datalink/utils/msg_adhoc.dart';
import 'package:adhoclibrary/src/datalink/utils/utils.dart';
import 'package:adhoclibrary/src/datalink/wifi/wifi_adhoc_manager.dart';
import 'package:meta/meta.dart';


class WifiServer extends ServiceServer {
  StreamSubscription<Socket> _listenStreamSub;
  HashMap<String, StreamSubscription<Uint8List>> _mapIpStream;
  HashMap<String, Socket> _mapIpSocket;
  ServerSocket _serverSocket;

  WifiServer(
    bool verbose,
    void Function(DiscoveryEvent) onEvent,
    void Function(dynamic) onError
  ) : super(verbose, Service.STATE_NONE, onEvent, onError) {
    WifiAdHocManager.setVerbose(verbose);
    _mapIpStream = HashMap();
    _mapIpSocket = HashMap();
  }

/*-------------------------------Public methods-------------------------------*/

  void listen({@required String hostIp, @required int serverPort}) async {
    if (v) log(ServiceServer.TAG, 'Server: listen()');

    _serverSocket = await ServerSocket.bind(hostIp, serverPort, shared: true);

    _listenStreamSub = _serverSocket.listen(
      (socket) {
        String remoteAddress = socket.remoteAddress.address;
        _mapIpSocket.putIfAbsent(remoteAddress, () => socket);
        _mapIpStream.putIfAbsent(remoteAddress, () => socket.listen(
          (data) async {
            String strMessage = Utf8Decoder().convert(data);
            MessageAdHoc message = MessageAdHoc.fromJson(json.decode(strMessage));
            onEvent(DiscoveryEvent(Service.MESSAGE_RECEIVED, message));
          },
          onError: (error) {
            // Error reported below as it is the same instance of 'error' below
            _closeSocket(remoteAddress);
          },
          onDone: () {
            onEvent(DiscoveryEvent(Service.CONNECTION_CLOSED, remoteAddress));
            _closeSocket(remoteAddress);
          }
        ));
      },
      onError: (error) => onEvent(DiscoveryEvent(Service.CONNECTION_EXCEPTION, error))
    );

    state = Service.STATE_LISTENING;
  }

  Future<void> stopListening() async {
    if (v) log(ServiceServer.TAG, 'Server: stopListening()');

    _mapIpStream.forEach((ip, stream) => stream.cancel());
    _mapIpStream.clear();
    _mapIpSocket.forEach((ipAddress, socket) => socket.destroy());
    _mapIpSocket.clear();

    await _listenStreamSub.cancel();
    await _serverSocket.close();

    state = Service.STATE_NONE;
  }

  Future<void> send(MessageAdHoc message, String remoteAddress) async {
    if (v) log(ServiceServer.TAG, 'Server: send()');

    _mapIpSocket[remoteAddress].write(json.encode(message.toJson()));
  }

  Future<void> cancelConnection(String remoteAddress) async {
    if (v) log(ServiceServer.TAG, 'cancelConnection()');

    _closeSocket(remoteAddress);
    onEvent(DiscoveryEvent(Service.CONNECTION_CLOSED, remoteAddress));
  }

/*------------------------------Private methods-------------------------------*/

  void _closeSocket(String remoteAddress) {
    _mapIpStream[remoteAddress].cancel();
    _mapIpStream.remove(remoteAddress);
    _mapIpSocket[remoteAddress].close();
    _mapIpSocket.remove(remoteAddress);
  }
}
