import 'dart:async';

import 'package:adhoc_plugin/src/datalink/service/adhoc_event.dart';


abstract class ServiceManager {
  final bool verbose;

  late bool isDiscovering;
  late StreamController<AdHocEvent> controller;

  ServiceManager(this.verbose) {
    this.isDiscovering = false;
    this.controller =  StreamController<AdHocEvent>.broadcast();
  }

/*------------------------------Getters & Setters-----------------------------*/

  Future<String?> get adapterName;

  Stream<AdHocEvent> get eventStream => controller.stream;

/*-------------------------------Public methods-------------------------------*/

  void close() {
    controller.close();
  }

  void initialize();

  void discovery();

  Future<bool?> resetDeviceName();

  Future<bool?> updateDeviceName(final String newName);
}