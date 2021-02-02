import 'dart:collection';

import 'package:adhoclibrary/src/datalink/service/adhoc_device.dart';
import 'package:adhoclibrary/src/datalink/service/service.dart';
import 'package:adhoclibrary/src/datalink/service/service_msg_listener.dart';
import 'package:adhoclibrary/src/datalink/utils/msg_adhoc.dart';


abstract class ServiceServer extends Service {
  static const String TAG = "[FlutterAdHoc][ServiceServer]";

  HashMap<String, AdHocDevice> connected;

  ServiceServer(
    bool verbose, int state, ServiceMessageListener serviceMessageListener
  ) : super(verbose, state, serviceMessageListener) {
    connected = HashMap<String, AdHocDevice>();
  }

/*------------------------------Getters & Setters-----------------------------*/

  HashMap<String, AdHocDevice> get activeConnections => connected;

/*-------------------------------Public methods-------------------------------*/

  void send(MessageAdHoc message, String address);

  void listen();

  void stopListening();
}
