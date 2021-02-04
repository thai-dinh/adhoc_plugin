import 'package:adhoclibrary/src/datalink/service/service.dart';
import 'package:adhoclibrary/src/datalink/service/service_msg_listener.dart';
import 'package:adhoclibrary/src/datalink/utils/msg_adhoc.dart';


abstract class ServiceServer extends Service {
  static const String TAG = "[FlutterAdHoc][ServiceServer]";

  List<String> connected;

  ServiceServer(
    bool verbose, int state, ServiceMessageListener serviceMessageListener
  ) : super(verbose, state, serviceMessageListener) {
    connected = List.empty(growable: true);
  }

  List<String> get activeConnections => connected;

  void send(MessageAdHoc message, String address);

  void listen([int serverPort]);

  void stopListening();
}
