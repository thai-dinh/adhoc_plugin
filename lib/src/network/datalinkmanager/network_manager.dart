import 'package:adhoclibrary/src/datalink/utils/msg_adhoc.dart';


class NetworkManager {
  String _mac;

  void Function(MessageAdHoc) _sendMessage;
  void Function() _disconnect;

  NetworkManager(this._mac, this._sendMessage, this._disconnect);

/*------------------------------Getters & Setters-----------------------------*/

  String get mac => _mac;

/*-------------------------------Public methods-------------------------------*/

  void sendMessage(MessageAdHoc message) => _sendMessage(message);

  void disconnect() => _disconnect();
}
