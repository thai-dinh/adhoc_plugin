import 'package:adhoclibrary/src/datalink/message/msg_adhoc.dart';

abstract class MessageManager {
  void sendMessage(MessageAdHoc msg);

  MessageAdHoc receiveMessage();
}