import 'package:adhoclibrary/src/datalink/service/service.dart';

abstract class ServiceServer extends Service {
  ServiceServer(int state) : super(state);

  void listen();

  void stopListening();
}
