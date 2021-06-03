import 'package:adhoc_plugin/src/datalink/utils/msg_adhoc.dart';


/// Class providing common interface for network operations regardless of the 
/// technology employed.
class NetworkManager {
  final Future<void> Function(MessageAdHoc) _sendMessage;
  final void Function() _disconnect;

  /// Creates a [NetworkManager] object.
  /// 
  /// The sending operation is given by [_sendMessage] and the connection
  /// abortion by [_disconnect].
  NetworkManager(this._sendMessage, this._disconnect);

/*-------------------------------Public methods-------------------------------*/

  /// Sends a [message] to a remote node.
  Future<void> sendMessage(MessageAdHoc message) async => await _sendMessage(message);

  /// Aborts a connection with a remote node.
  void disconnect() => _disconnect();
}
