import 'package:AdHocLibrary/datalink/service/service.dart';

abstract class ServiceServer extends Service {
  ServiceServer();

  void listen();

  void stopListening();
}