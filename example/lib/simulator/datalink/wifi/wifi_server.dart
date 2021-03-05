import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:adhoclibrary/adhoclibrary.dart';
import 'package:meta/meta.dart';


class WifiServer extends ServiceServer {
  StreamController<ConnectionEvent> _connectCtrl;
  StreamController<MessageAdHoc> _messageCtrl;
  StreamSubscription<Socket> _listenStreamSub;
  HashMap<String, StreamSubscription<Uint8List>> _mapIpStream;
  HashMap<String, Socket> _mapIpSocket;
  ServerSocket _serverSocket;

  WifiServer(bool verbose) : super(verbose, Service.STATE_NONE) {
    WifiAdHocManager.setVerbose(verbose);
    this._connectCtrl = StreamController<ConnectionEvent>();
    this._messageCtrl = StreamController<MessageAdHoc>();
    this._mapIpStream = HashMap();
    this._mapIpSocket = HashMap();
  }

/*------------------------------Getters & Setters-----------------------------*/

  Stream<ConnectionEvent> get connStatusStream => _connectCtrl.stream;

  Stream<MessageAdHoc> get messageStream => _messageCtrl.stream;

/*-------------------------------Public methods-------------------------------*/

  void start({@required String hostIp, @required int serverPort}) async {
    if (verbose) log(ServiceServer.TAG, 'Server: start()');

    _serverSocket = await ServerSocket.bind(hostIp, serverPort, shared: true);
  
    _listenStreamSub = _serverSocket.listen(
      (socket) {
        String remoteAddress = socket.remotePort.toString();
        _mapIpSocket.putIfAbsent(remoteAddress, () => socket);
        _mapIpStream.putIfAbsent(remoteAddress, () => socket.listen(
          (data) async {
            if (verbose) log(ServiceServer.TAG, 'received message from ${socket.port}:${socket.remotePort}');

            MessageAdHoc message;
            String strMessage = Utf8Decoder().convert(data);
            List<String> strMessages = strMessage.split('}{');
            for (int i = 0; i < strMessages.length; i++) {
              if (strMessages.length == 1) {
                message = MessageAdHoc.fromJson(json.decode(strMessages[i]));
              } else if (i == 0) {
                message = MessageAdHoc.fromJson(json.decode(strMessages[i] + '}'));
              } else if (i == strMessages.length - 1) {
                message = MessageAdHoc.fromJson(json.decode('{' + strMessages[i]));
              } else {
                message = MessageAdHoc.fromJson(json.decode('{' + strMessages[i] + '}'));
              }

              _messageCtrl.add(message);
            }
          },
          onError: (error) {
            // Error reported below as it is the same instance of 'error' as below
            _closeSocket(remoteAddress);
          },
          onDone: () {
            _closeSocket(remoteAddress);
            _connectCtrl.add(ConnectionEvent(Service.CONNECTION_CLOSED, address: remoteAddress));
          }
        ));

        _connectCtrl.add(ConnectionEvent(Service.CONNECTION_PERFORMED, address: remoteAddress));
      },
      onError: (error) {
        _connectCtrl.add(ConnectionEvent(Service.CONNECTION_EXCEPTION, error: error));
      }
    );

    state = Service.STATE_LISTENING;
  }

  Future<void> stopListening() async {
    if (verbose) log(ServiceServer.TAG, 'stopListening()');

    _mapIpStream.forEach((ip, stream) => stream.cancel());
    _mapIpStream.clear();
    _mapIpSocket.forEach((ipAddress, socket) => socket.destroy());
    _mapIpSocket.clear();

    await _listenStreamSub.cancel();
    await _serverSocket.close();

    state = Service.STATE_NONE;
  }

  Future<void> send(MessageAdHoc message, String remoteAddress) async {
    if (verbose) log(ServiceServer.TAG, 'send() to $remoteAddress');

    _mapIpSocket[remoteAddress].write(json.encode(message.toJson()));
  }

  Future<void> cancelConnection(String remoteAddress) async {
    if (verbose) log(ServiceServer.TAG, 'cancelConnection() - $remoteAddress');

    _closeSocket(remoteAddress);
    _connectCtrl.add(ConnectionEvent(Service.CONNECTION_CLOSED, address: remoteAddress));
  }

/*------------------------------Private methods-------------------------------*/

  void _closeSocket(String remoteAddress) {
    _mapIpStream[remoteAddress].cancel();
    _mapIpStream.remove(remoteAddress);
    _mapIpSocket[remoteAddress].destroy();
    _mapIpSocket[remoteAddress].close();
    _mapIpSocket.remove(remoteAddress);
  }
}
