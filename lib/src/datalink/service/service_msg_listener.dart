import 'package:adhoclibrary/src/datalink/utils/msg_adhoc.dart';


class ServiceMessageListener {
  void Function(MessageAdHoc message) _onMessageReceived;
  void Function(String remoteAddress) _onConnectionClosed;
  void Function(String remoteAddress) _onConnection;
  void Function(Exception exception) _onConnectionFailed;
  void Function(Exception exception) _onMsgException;

  ServiceMessageListener({
    void Function(MessageAdHoc message) onMessageReceived,
    void Function(String remoteAddress) onConnectionClosed,
    void Function(String remoteAddress) onConnection,
    void Function(Exception exception) onConnectionFailed,
    void Function(Exception exception) onMsgException
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
