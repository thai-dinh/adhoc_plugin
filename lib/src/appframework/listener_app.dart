import 'package:adhoclibrary/src/datalink/service/adhoc_device.dart';


class ListenerApp {
  void Function(AdHocDevice, Object) _onReceivedData;
  void Function(AdHocDevice, Object) _onForwardData;
  void Function(AdHocDevice) _onConnection;
  void Function(Exception) _onConnectionFailed;
  void Function(AdHocDevice) _onConnectionClosed;
  void Function(Exception) _onConnectionClosedFailed;
  void Function(Exception) _processMsgException;

  ListenerApp({
    void Function(AdHocDevice, Object) onReceivedData,
    void Function(AdHocDevice, Object) onForwardData,
    void Function(AdHocDevice) onConnection,
    void Function(Exception) onConnectionFailed,
    void Function(AdHocDevice) onConnectionClosed,
    void Function(Exception) onConnectionClosedFailed,
    void Function(Exception) processMsgException
  }) {
    this._onReceivedData = onReceivedData;
    this._onForwardData = onForwardData;
    this._onConnection = onConnection;
    this._onConnectionFailed = onConnectionFailed;
    this._onConnectionClosed = onConnectionClosed;
    this._onConnectionClosedFailed = onConnectionClosedFailed;
    this._processMsgException = processMsgException;
  }

  void onReceivedData(AdHocDevice adHocDevice, Object pdu) {
    _onReceivedData(adHocDevice, pdu);
  }

  void onForwardData(AdHocDevice adHocDevice, Object pdu) {
    _onForwardData(adHocDevice, pdu);
  }

  void onConnection(AdHocDevice adHocDevice) {
    _onConnection(adHocDevice);
  }

  void onConnectionFailed(Exception exception) {
    _onConnectionFailed(exception);
  }

  void onConnectionClosed(AdHocDevice adHocDevice) {
    _onConnectionClosed(adHocDevice);
  }

  void onConnectionClosedFailed(Exception exception) {
    _onConnectionClosedFailed(exception);
  }

  void processMsgException(Exception exception) {
    _processMsgException(exception);
  }
}
