import 'package:adhoc_plugin/src/datalink/utils/msg_adhoc.dart';


class NetworkManager {
  Future<void> Function(MessageAdHoc) _sendMessage;
  void Function() _disconnect;

  NetworkManager(this._sendMessage, this._disconnect);

/*-------------------------------Public methods-------------------------------*/

  Future<void> sendMessage(MessageAdHoc message) async => await _sendMessage(message);

  void disconnect() => _disconnect();
}
