import 'package:AdHocLibrary/datalink/sockets/isocket.dart';
import 'package:AdHocLibrary/datalink/utils/message_adhoc.dart';

class AdHocBluetoothSocket implements ISocket {
  AdHocBluetoothSocket();

  String remoteAddress() => null;

  void close() { }

  void listen(Function onData) { }

  void write(MessageAdHoc msg) { }
}