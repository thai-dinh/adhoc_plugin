import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:adhoclibrary/adhoclibrary.dart';
import 'package:adhoclibrary/src/datalink/service/connect_status.dart';
import 'package:adhoclibrary/src/datalink/service/service_server.dart';
import 'package:adhoclibrary/src/datalink/service/service.dart';
import 'package:adhoclibrary/src/datalink/utils/msg_adhoc.dart';
import 'package:adhoclibrary/src/datalink/utils/utils.dart';
import 'package:adhoclibrary/src/datalink/wifi/wifi_adhoc_manager.dart';
import 'package:meta/meta.dart';


class WifiServer extends ServiceServer {
  StreamController<ConnectStatus> _connectCtrl;
  StreamController<MessageAdHoc> _messageCtrl;
  StreamSubscription<Socket> _listenStreamSub;
  HashMap<String, StreamSubscription<Uint8List>> _mapIpStream;
  HashMap<String, Socket> _mapIpSocket;
  ServerSocket _serverSocket;

  WifiServer(bool verbose) : super(verbose, Service.STATE_NONE) {
    WifiAdHocManager.setVerbose(verbose);
    this._connectCtrl = StreamController<ConnectStatus>();
    this._messageCtrl = StreamController<MessageAdHoc>();
    this._mapIpStream = HashMap();
    this._mapIpSocket = HashMap();
  }

/*------------------------------Getters & Setters-----------------------------*/

  Stream<ConnectStatus> get connStatusStream async* {
    await for (ConnectStatus status in _connectCtrl.stream) {
      yield status;
    }
  }

  Stream<MessageAdHoc> get messageStream async* {
    await for (MessageAdHoc msg in _messageCtrl.stream) {
      yield msg;
    }
  }

/*-------------------------------Public methods-------------------------------*/

  void start({@required String hostIp, @required int serverPort}) async {
    if (verbose) log(ServiceServer.TAG, 'Server: start()');

    _serverSocket = await ServerSocket.bind(hostIp, serverPort, shared: true);
  
    _listenStreamSub = _serverSocket.listen(
      (socket) {
        String remoteAddress = socket.remoteAddress.address;
        _mapIpSocket.putIfAbsent(remoteAddress, () => socket);
        _mapIpStream.putIfAbsent(remoteAddress, () => socket.listen(
          (data) async {
            String strMessage = Utf8Decoder().convert(data);
            _messageCtrl.add(MessageAdHoc.fromJson(json.decode(strMessage)));
          },
          onError: (error) {
            // Error reported below as it is the same instance of 'error' below
            _closeSocket(remoteAddress);
          },
          onDone: () {
            _closeSocket(remoteAddress);
            _connectCtrl.add(ConnectStatus(Service.STATE_NONE, address: remoteAddress));
          }
        ));

        _connectCtrl.add(ConnectStatus(Service.STATE_CONNECTED, address: remoteAddress));
      },
      onError: (error) {
        _connectCtrl.add(ConnectStatus(Service.CONNECTION_EXCEPTION, error: error));
      }
    );

    state = Service.STATE_LISTENING;
  }

  Future<void> stopListening() async {
    if (verbose) log(ServiceServer.TAG, 'Server: stopListening()');

    _mapIpStream.forEach((ip, stream) => stream.cancel());
    _mapIpStream.clear();
    _mapIpSocket.forEach((ipAddress, socket) => socket.destroy());
    _mapIpSocket.clear();

    await _listenStreamSub.cancel();
    await _serverSocket.close();

    state = Service.STATE_NONE;
  }

  Future<void> send(MessageAdHoc message, String remoteAddress) async {
    if (verbose) log(ServiceServer.TAG, 'Server: send()');

    _mapIpSocket[remoteAddress].write(json.encode(message.toJson()));
  }

  Future<void> cancelConnection(String remoteAddress) async {
    if (verbose) log(ServiceServer.TAG, 'cancelConnection()');

    _closeSocket(remoteAddress);
    _connectCtrl.add(ConnectStatus(Service.STATE_NONE, address: remoteAddress));
  }

/*------------------------------Private methods-------------------------------*/

  void _closeSocket(String remoteAddress) {
    _mapIpStream[remoteAddress].cancel();
    _mapIpStream.remove(remoteAddress);
    _mapIpSocket[remoteAddress].close();
    _mapIpSocket.remove(remoteAddress);
  }
}
