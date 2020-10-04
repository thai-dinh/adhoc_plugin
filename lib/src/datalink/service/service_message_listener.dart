import 'package:AdHocLibrary/src/datalink/utils/message_adhoc.dart';

abstract class ServiceMessageListener {
    void onMessageReceived(MessageAdHoc message);

    void onConnectionClosed(String remoteAddress);

    void onConnection(String remoteAddress);

    void onConnectionFailed(Exception exception);

    void onMsgException(Exception exception);
}
