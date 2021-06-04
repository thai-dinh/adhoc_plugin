import 'package:adhoc_plugin/src/appframework/constants.dart';
import 'package:adhoc_plugin/src/datalink/service/adhoc_device.dart';


class Event {
  late final AdHocType type;
  late AdHocDevice? device;
  late Object? data;

  Event(this.type, {this.device, this.data});
}
