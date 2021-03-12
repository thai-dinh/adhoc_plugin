import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:adhoclibrary/src/datalink/service/connection_event.dart';
import 'package:adhoclibrary/src/datalink/service/service_server.dart';
import 'package:adhoclibrary/src/datalink/service/service.dart';
import 'package:adhoclibrary/src/datalink/utils/msg_adhoc.dart';
import 'package:adhoclibrary/src/datalink/utils/utils.dart';
import 'package:adhoclibrary/src/datalink/wifi/wifi_adhoc_manager.dart';
import 'package:meta/meta.dart';


class WifiServer extends ServiceServer {
  StreamController<ConnectionEvent> _connectCtrl;
  StreamController<MessageAdHoc> _messageCtrl;
  StreamSubscription<Socket> _listenStreamSub;
  HashMap<String, HashMap<int, String>> _mapNameData;
  HashMap<String, StreamSubscription<Uint8List>> _mapIpStream;
  HashMap<String, Socket> _mapIpSocket;
  ServerSocket _serverSocket;

  StringBuffer _buffer = StringBuffer();

  WifiServer(bool verbose) : super(verbose, Service.STATE_NONE) {
    WifiAdHocManager.setVerbose(verbose);
    this._connectCtrl = StreamController<ConnectionEvent>();
    this._messageCtrl = StreamController<MessageAdHoc>();
    this._mapNameData = HashMap();
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
        String remoteAddress = socket.remoteAddress.address;
        _mapIpSocket.putIfAbsent(remoteAddress, () => socket);
        _mapIpStream.putIfAbsent(remoteAddress, () => socket.listen(
          (data) async {
            if (verbose) log(ServiceServer.TAG, 'received message from $remoteAddress:${socket.remotePort}');

            _mapNameData.putIfAbsent(remoteAddress, () => HashMap());

            String msg = Utf8Decoder().convert(data);
            if (msg[0].compareTo('{') == 0 && msg[msg.length-1].compareTo('}') == 0) {
              _messageCtrl.add(MessageAdHoc.fromJson(json.decode(msg)));
            } else if (msg[msg.length-1].compareTo('}') == 0) {
              _buffer.write(msg);
              for (MessageAdHoc _msg in splitMessages(_buffer.toString()))
                _messageCtrl.add(_msg);
              _buffer.clear();
            } else {
              _buffer.write(msg);
            }
          },
          onError: (error) {
            // Error reported below as it is the same instance of 'error' below
            _closeSocket(remoteAddress);
          },
          onDone: () {
            _closeSocket(remoteAddress);
            _connectCtrl.add(ConnectionEvent(Service.CONNECTION_CLOSED, address: remoteAddress));
          }
        )
        );

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

    String msg = json.encode(message.toJson());
    int mtu = 7500, length = msg.length, start = 0, end = mtu;

    while (length > mtu) {
      _mapIpSocket[remoteAddress].write(msg.substring(start, end));
      start = end;
      end += mtu;
      length -= mtu;
    }

    _mapIpSocket[remoteAddress].write(msg.substring(start, msg.length));
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
    _mapIpSocket[remoteAddress].close();
    _mapIpSocket.remove(remoteAddress);
  }
}
