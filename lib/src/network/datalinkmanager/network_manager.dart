import 'package:adhoclibrary/src/datalink/utils/msg_adhoc.dart';


class NetworkManager {
  void Function(MessageAdHoc) _sendMessage;
  void Function() _disconnect;

  NetworkManager(this._sendMessage, this._disconnect);

/*-------------------------------Public methods-------------------------------*/

  void sendMessage(MessageAdHoc message) => _sendMessage(message);

  void disconnect() => _disconnect();
}
