import 'package:adhoclibrary/src/datalink/service/service.dart';


abstract class ServiceServer extends Service {
  static const String TAG = "[FlutterAdHoc][ServiceServer]";

  ServiceServer(bool verbose, int state) : super(verbose, state);

  void listen();

  void stopListening();
}
