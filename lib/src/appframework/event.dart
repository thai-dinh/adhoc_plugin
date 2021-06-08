import 'package:adhoc_plugin/src/appframework/constants.dart';
import 'package:adhoc_plugin/src/datalink/service/adhoc_device.dart';

/// Class encapsulating the data received from lower layers of the library.
class Event {
  late final AdHocType type;
  late AdHocDevice? device;
  late Object? data;

  /// Creates an [Event] object.
  /// 
  /// The event is determined by its [type], which in turn indicates if this
  /// object has a payload [data] or a sender ad hoc device representation [device].
  Event(this.type, {this.device, this.data});
}
