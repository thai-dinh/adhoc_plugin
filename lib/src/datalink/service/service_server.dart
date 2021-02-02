import 'package:adhoclibrary/src/datalink/service/service.dart';
import 'package:adhoclibrary/src/datalink/service/service_msg_listener.dart';


abstract class ServiceServer extends Service {
  static const String TAG = "[FlutterAdHoc][ServiceServer]";

  ServiceServer(
    bool verbose, int state, ServiceMessageListener serviceMessageListener
  ) : super(verbose, state, serviceMessageListener);

  void listen();

  void stopListening();
}
