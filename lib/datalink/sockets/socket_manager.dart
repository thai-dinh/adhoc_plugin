import 'package:AdHocLibrary/datalink/sockets/isocket.dart';
import 'package:AdHocLibrary/datalink/utils/message_adhoc.dart';

class SocketManager {
  final ISocket _isocket;

  List<MessageAdHoc> _messages;
  String _remoteSocketAddress;

  SocketManager(this._isocket) {
    _isocket.listen(_onMessage);
    _remoteSocketAddress = _isocket.remoteAddress;
    _messages = List();
  }

  String get remoteSocketAddress => _remoteSocketAddress;

  void _onMessage(MessageAdHoc message) => _messages.add(message);

  void closeConnection() => _isocket.close();

  void sendMessage(MessageAdHoc msg) => _isocket.write(msg);

  MessageAdHoc receiveMessage() 
    => _messages.isNotEmpty ? _messages.removeAt(0) : null;
}