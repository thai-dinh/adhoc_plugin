import 'package:adhoclibrary/src/datalink/utils/msg_adhoc.dart';


class ServiceMessageListener {
  void Function(MessageAdHoc) _onMessageReceived;
  void Function(String) _onConnectionClosed;
  void Function(String) _onConnection;
  void Function(Exception) _onConnectionFailed;
  void Function(Exception) _onMsgException;

  ServiceMessageListener({
    void Function(MessageAdHoc) onMessageReceived,
    void Function(String) onConnectionClosed,
    void Function(String) onConnection,
    void Function(Exception) onConnectionFailed,
    void Function(Exception) onMsgException
  }) {
    this._onMessageReceived = onMessageReceived;
    this._onConnectionClosed = onConnectionClosed;
    this._onConnection = onConnection;
    this._onConnectionFailed = onConnectionFailed;
    this._onMsgException = onMsgException;
  }

  void onMessageReceived(MessageAdHoc message) {
    _onMessageReceived(message);
  }

  void onConnectionClosed(String remoteAddress) {
    _onConnectionClosed(remoteAddress);
  }

  void onConnection(String remoteAddress) {
    _onConnection(remoteAddress);
  }

  void onConnectionFailed(Exception exception) {
    _onConnectionFailed(exception);
  }

  void onMsgException(Exception exception) {
    _onMsgException(exception);
  }
}
