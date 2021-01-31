import 'dart:collection';

import 'package:adhoclibrary/src/appframework/config/config.dart';
import 'package:adhoclibrary/src/datalink/service/adhoc_device.dart';
import 'package:adhoclibrary/src/datalink/service/service_server.dart';
import 'package:adhoclibrary/src/network/datalinkmanager/abstract_wrapper.dart';

abstract class WrapperConnOriented extends AbstractWrapper {
  int attempts;
  ServiceServer serviceServer;

  WrapperConnOriented(
    bool verbose,
    Config config,
    HashMap<String, AdHocDevice> mapAddressDevice
  ) : super(verbose, config, mapAddressDevice);
}
