import 'package:AdHocLibrary/datalink/sockets/bt_socket.dart';
import 'package:AdHocLibrary/datalink/sockets/isocket.dart';
import 'package:AdHocLibrary/datalink/utils/message_adhoc.dart';

class AdHocBluetoothSocket implements ISocket {
  final String _address;

  BluetoothSocket _socket;

  AdHocBluetoothSocket(this._address) {
    this._socket = new BluetoothSocket(_address);
  }

  String remoteAddress() => _address;

  void close() => _socket.close();

  void listen(Function onData) { }

  void write(MessageAdHoc msg) { }
}