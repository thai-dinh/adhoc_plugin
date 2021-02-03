import 'dart:collection';

import 'package:adhoclibrary/src/datalink/service/adhoc_device.dart';


class FloodMsg {
  String id;
  HashSet<AdHocDevice> adHocDevices;

  FloodMsg([this.id, this.adHocDevices]);
}
