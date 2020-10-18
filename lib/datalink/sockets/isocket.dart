import 'package:AdHocLibrary/datalink/utils/message_adhoc.dart';

abstract class ISocket {
  String remoteAddress();

  void close();

  void listen(Function onData);

  void write(MessageAdHoc msg);
}