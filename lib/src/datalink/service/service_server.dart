import 'package:adhoclibrary/src/datalink/service/discovery_event.dart';
import 'package:adhoclibrary/src/datalink/service/service.dart';
import 'package:adhoclibrary/src/datalink/utils/msg_adhoc.dart';


abstract class ServiceServer extends Service {
  static const String TAG = "[ServiceServer]";

  List<String> _activeConnections;

  ServiceServer(
    bool verbose, int state, 
    void Function(DiscoveryEvent) onEvent,
    void Function(dynamic) onError
  ) : super(verbose, state, onEvent, onError) {
    _activeConnections = List.empty(growable: true);
  }

/*------------------------------Getters & Setters-----------------------------*/

  List<String> get activeConnections => _activeConnections;

/*-------------------------------Public methods-------------------------------*/

  void addActiveConnection(String mac) {
    _activeConnections.add(mac);
  }

  void removeInactiveConnection(String mac) {
    _activeConnections.remove(mac);
  }

  bool containConnection(String mac) {
    return _activeConnections.contains(mac);
  }

  void cancelConnection(String mac);

  void send(MessageAdHoc message, String mac);
}
