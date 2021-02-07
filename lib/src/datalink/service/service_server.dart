import 'dart:collection';

import 'package:adhoclibrary/src/datalink/service/discovery_event.dart';
import 'package:adhoclibrary/src/datalink/service/identifier.dart';
import 'package:adhoclibrary/src/datalink/service/service.dart';
import 'package:adhoclibrary/src/datalink/utils/msg_adhoc.dart';


abstract class ServiceServer extends Service {
  static const String TAG = "[ServiceServer]";

  HashMap<String, Identifier> _activeConnections;

  ServiceServer(
    bool verbose, int state, 
    void Function(DiscoveryEvent) onEvent,
    void Function(dynamic) onError
  ) : super(verbose, state, onEvent, onError) {
    _activeConnections = HashMap();
  }

/*------------------------------Getters & Setters-----------------------------*/

  HashMap<String, Identifier> get activeConnections => _activeConnections;

/*-------------------------------Public methods-------------------------------*/

  void addActiveConnection(Identifier id) {
    _activeConnections.update(
      id.mac, (value) => id, ifAbsent: () => id
    );
  }

  void removeInactiveConnection(Identifier id) {
    _activeConnections.remove(id.mac);
  }

  bool containConnection(Identifier id) {
    if (id.mac == '') {
      for (final Identifier _id in _activeConnections.values) {
        if (_id.ulid == id.ulid)
          return true;
      }

      return false;
    }

    return _activeConnections.containsKey(id.mac);
  }

  void send(MessageAdHoc message, Identifier id);
}
