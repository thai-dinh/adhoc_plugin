import 'package:adhoclibrary/src/datalink/service/service.dart';

abstract class ServiceServer extends Service {
  static const String TAG = "[FlutterAdHoc][ServiceServer]";

  ServiceServer(int state) : super(state);

  void listen();

  void stopListening();
}
