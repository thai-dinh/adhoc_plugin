import '../service/service.dart';
import '../utils/msg_adhoc.dart';


/// Abstract class defining the server's logic and methods. It aims to serve as 
/// a common interface for the services 'BleServer' and 'WifiServer' classes.
abstract class ServiceServer extends Service {
  static const String TAG = "[ServiceServer]";

  late List<String> _activeConnections;

  /// Creates a [ServiceServer] object.
  /// 
  /// The debug/verbose mode is set if [verbose] is true.
  ServiceServer(bool verbose) : super(verbose) {
    this._activeConnections = List.empty(growable: true);
  }

/*------------------------------Getters & Setters-----------------------------*/

  /// Returns the list of active connections (MAC address).
  List<String> get activeConnections => _activeConnections;

/*-------------------------------Public methods-------------------------------*/

  /// Sends a [message] to the remote device of MAC address [mac].
  Future<void> send(MessageAdHoc message, String mac);


  /// Adds the MAC address [mac] of the active connection.
  void addActiveConnection(String mac) {
    _activeConnections.add(mac);
  }


  /// Removes the MAC address [mac] of the active connection.
  void removeInactiveConnection(String mac) {
    if (containConnection(mac))
      _activeConnections.remove(mac);
  }


  /// Checks if there is a active connection to the server.
  /// 
  /// Returns true if there exists an active connection with the remote device
  /// of MAC address [mac], otherwise false.
  bool containConnection(String mac) {
    return _activeConnections.contains(mac);
  }


  /// Cancels an active connection with the remote device of MAC address [mac].
  Future<void> cancelConnection(String mac);
}
