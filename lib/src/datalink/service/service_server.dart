import 'package:adhoc_plugin/src/datalink/service/constants.dart';
import 'package:adhoc_plugin/src/datalink/service/service.dart';
import 'package:adhoc_plugin/src/datalink/utils/msg_adhoc.dart';


abstract class ServiceServer extends Service {
  static const String TAG = "[ServiceServer]";

  List<String>? _activeConnections;

  ServiceServer(bool verbose) : super(verbose, STATE_NONE) {
    _activeConnections = List.empty(growable: true);
  }

/*------------------------------Getters & Setters-----------------------------*/

  List<String>? get activeConnections => _activeConnections;

/*-------------------------------Public methods-------------------------------*/

  void addActiveConnection(String mac) {
    _activeConnections!.add(mac);
  }

  void removeInactiveConnection(String mac) {
    if (containConnection(mac))
      _activeConnections!.remove(mac);
  }

  bool containConnection(String? mac) {
    return _activeConnections!.contains(mac);
  }

  Future<void> cancelConnection(String? mac);

  Future<void> send(MessageAdHoc message, String? mac);
}
