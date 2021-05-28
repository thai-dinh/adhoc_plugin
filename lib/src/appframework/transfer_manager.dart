import 'dart:collection';

import 'config.dart';
import '../datalink/exceptions/device_failure.dart';
import '../datalink/service/adhoc_device.dart';
import '../datalink/service/adhoc_event.dart';
import '../datalink/service/constants.dart';
import '../network/datalinkmanager/datalink_manager.dart';
import '../presentation/presentation_manager.dart';


/// Class providing high-Level APIs to manage ad hoc networks and network 
/// communications.
class TransferManager {
  final bool _verbose;

  late Config _config;
  late DataLinkManager _datalinkManager;
  late PresentationManager _securityManager;


  /// Creates a [TransferManager] object.
  /// 
  /// The debug/verbose mode is set if [_verbose] is true.
  /// 
  /// This object is configured according to [config], which contains specific 
  /// configurations.
  TransferManager(this._verbose, {Config? config}) {
    this._config = config == null ? Config() : config;
    this._securityManager = PresentationManager(_verbose, _config);
    this._datalinkManager = _securityManager.datalinkManager;
  }

/*------------------------------Getters & Setters-----------------------------*/

  /// List of direct neighors of this node ([List] of [AdHocDevice]).
  List<AdHocDevice> get directNeighbors => _securityManager.directNeighbors;

  /// Stream of lower layers ad hoc events ([AdHocEvent]).
  Stream<AdHocEvent> get eventStream => _securityManager.eventStream;

  /// Current label ([String]) that identifies uniquely the device.
  String get ownAddress => _config.label;

  /// Configuration object ([Config]), which represents the current configuration.
  Config get config => _config;

  /// Bluetooth paired devices as [HashMap] of <[String], [AdHocDevice]>.
  Future<HashMap<String, AdHocDevice>> get pairedBluetoothDevices async {
    return _datalinkManager.getPaired();
  }

  /// Wi-Fi adapter name as [String].
  Future<String> get wifiAdapterName async {
    return _datalinkManager.getAdapterName(WIFI);
  }

  /// Bluetooth adapter name as [String].
  Future<String> get bluetoothAdapterName async {
    return _datalinkManager.getAdapterName(BLE);
  }

  /// Actives adapter names as a [HashMap] representing the adapter name of the 
  /// specified technology. The key value are integer, where a '0' value 
  /// represents Wi-Fi and a '1' value Bluetooth Low Energy.
  Future<HashMap<int, String>> get activeAdapterNames async {
    return _datalinkManager.getActiveAdapterNames();
  }

/*-------------------------------Group Methods--------------------------------*/

  /// Creates a secure group.
  void createGroup() {
    if (_datalinkManager.checkState() == 0)
      throw DeviceFailureException('No wifi and bluetooth connectivity');

    _securityManager.groupController.createGroup();
  }


  /// Joins an existing secure group.
  void joinGroup() {
    if (_datalinkManager.checkState() == 0)
      throw DeviceFailureException('No wifi and bluetooth connectivity');

    _securityManager.groupController.joinSecureGroup();
  }


  /// Leaves an existing secure group.
  void leaveGroup() {
    if (_datalinkManager.checkState() == 0)
      throw DeviceFailureException('No wifi and bluetooth connectivity');

    _securityManager.groupController.leaveSecureGroup();
  }


  /// Sends a confidential message to the secure group members.
  /// 
  /// The payload [data] is encrypted.
  void sendMessageToGroup(Object data) {
    if (_datalinkManager.checkState() == 0)
      throw DeviceFailureException('No wifi and bluetooth connectivity');

    _securityManager.groupController.sendMessageToGroup(data);
  }

/*------------------------------Network Methods------------------------------*/

  /// Sends a message to a remote node.
  /// 
  /// The message payload is set to [data] and the message is sent to the remote
  /// node, which is specified by [destination].
  void sendMessageTo(Object data, String destination) {
    if (_datalinkManager.checkState() == 0)
      throw DeviceFailureException('No wifi and bluetooth connectivity');

    _securityManager.send(data, destination, false);
  }


  /// Sends a message, whose payload is encrypted, to a remote node.
  /// 
  /// The message payload is set to [data] and is encrypted. The message is sent 
  /// to the remote node, which is specified by [destination].
  void sendEncryptedMessageTo(Object data, String destination) {
    if (_datalinkManager.checkState() == 0)
      throw DeviceFailureException('No wifi and bluetooth connectivity');

    _securityManager.send(data, destination, true);
  }


  /// Broadcasts a message to all directly connected nodes.
  /// 
  /// The message payload is set to [data].
  /// 
  /// Returns true upon successful broadcast, otherwise false.
  Future<bool> broadcast(Object data) async {
    if (_datalinkManager.checkState() == 0)
      throw DeviceFailureException('No wifi and bluetooth connectivity');

    return await _securityManager.broadcast(data, false);
  }


  /// Broadcasts a message, whose payload is encrypted, to all directly 
  /// connected nodes.
  /// 
  /// The message payload is set to [data] and is encrypted.
  /// 
  /// Returns true upon successful broadcast, otherwise false.
  Future<bool> encryptedBroadcast(Object data) async {
    if (_datalinkManager.checkState() == 0)
      throw DeviceFailureException('No wifi and bluetooth connectivity');

    return await _securityManager.broadcast(data, true);
  }


  /// Broadcasts a message to all directly connected nodes except the excluded
  /// one.
  /// 
  /// The message payload is set to [data].
  /// 
  /// The node specified by [excluded] is not included in the broadcast.
  /// 
  /// Returns true upon successful broadcast, otherwise false.
  Future<bool> broadcastExcept(Object data, AdHocDevice excluded) async {
    if (_datalinkManager.checkState() == 0)
      throw DeviceFailureException('No wifi and bluetooth connectivity');

    return await _securityManager.broadcastExcept(data, excluded.label!, false);
  }


  /// Broadcasts a message, whose payload is encrypted, to all directly 
  /// connected nodes except the excluded one.
  /// 
  /// The message payload is set to [data] and is encrypted.
  /// 
  /// The node specified by [excluded] is not included in the broadcast.
  /// 
  /// Returns true upon successful broadcast, otherwise false.
  Future<bool> encryptedBroadcastExcept(Object data, AdHocDevice excluded) async {
    if (_datalinkManager.checkState() == 0)
      throw DeviceFailureException('No wifi and bluetooth connectivity');

    return await _securityManager.broadcastExcept(data, excluded.label!, true);
  }

/*-----------------------------Data-link Methods-----------------------------*/

  /// Performs a discovery process. 
  /// 
  /// If the Bluetooth Low Energy and Wi-Fi are enabled, the two discoveries are 
  /// performed in parallel. A discovery process lasts for at least 10/12 seconds.
  void discovery() => _datalinkManager.discovery();


  /// Attempts to connect to a remote peer.
  /// 
  /// The connection to [device] process is attempted. 
  /// 
  /// if [attempts] is set, then it is done "attempts" times. Otherwise, the
  /// connection is only attempted once.
  Future<void> connect(AdHocDevice device, [int? attempts]) async {        
    if (_datalinkManager.checkState() == 0)
      throw DeviceFailureException('No wifi and bluetooth connectivity');

    await _datalinkManager.connect(attempts == null ? 1 : attempts, device);
  }


  /// Stop the listening process of incoming connections.
  void stopListening() {
    _datalinkManager.stopListening();
  }


  /// Disconnects the current node from a specific remote node.
  /// 
  /// The remote node is identified by [device].
  void disconnect(AdHocDevice device) => _datalinkManager.disconnect(device.label!);


  /// Disconnects the current node from all remote node.
  void disconnectAll() => _datalinkManager.disconnectAll();


  /// Check if Bluetooth is enabled.
  /// 
  /// Returns true if it is, otherwise false.
  bool isBluetoothEnabled() {
    return _datalinkManager.isEnabled(BLE);
  }


  /// Checks if Wi-Fi is enabled.
  /// 
  /// Returns true if it is, otherwise false.
  bool isWifiEnabled() {
    return _datalinkManager.isEnabled(WIFI);
  }


  /// Enables the Bluetooth adapter.
  /// 
  /// The device is set into discovery mode for [duration] ms.
  /// 
  /// Throws an [BadDurationException] if the given duration exceeds 3600 
  /// seconds or is negative.
  void enableBle(int duration) {
    _datalinkManager.enable(duration, BLE);
  }


  /// Enables the Wi-Fi adapter.
  /// 
  /// The device is set into discovery mode for [duration] ms.
  /// 
  /// Throws an [BadDurationException] if the given duration exceeds 3600 
  /// seconds or is negative.
  void enableWifi(int duration) {
    _datalinkManager.enable(duration, WIFI);
  }


  /// Enables the Bluetooth and Wi-Fi adapter.
  /// 
  /// The device is set into discovery mode for both technologies for 3600 ms.
  void enable() {
    _datalinkManager.enableAll();
  }


  /// Updates the name of the Wi-Fi adapter.
  /// 
  /// The new name is given by [newName].
  /// 
  /// Returns true if it has been set successfully, otherwise false.
  Future<bool> updateWifiAdapterName(String newName) async {
    return _datalinkManager.updateAdapterName(WIFI, newName);
  }


  /// Updates the name of the Bluetooth adapter.
  /// 
  /// The new name is given by [newName].
  /// 
  /// Returns true if it has been set successfully, otherwise false.
  Future<bool> updateBluetoothAdapterName(String newName) async {
    return _datalinkManager.updateAdapterName(BLE, newName);
  }


  /// Resets the adapter name of a particular technology adapter.
  /// 
  /// The technology is specified by [type], where a '0' value represents Wi-Fi
  /// and a '1' value Bluetooth Low Energy.
  void resetAdapterName(int type) {
    _datalinkManager.resetAdapterName(type);
  }


  /// Removes the current device from its Wi-Fi group.
  void removeWifiGroup() {
    _datalinkManager.removeGroup();
  }


  /// Checks if the current device is the Wi-Fi group owner.
  /// 
  /// Returns true if it is, otherwise false.
  bool isWifiGroupOwner() {
    return _datalinkManager.isWifiGroupOwner();
  }
}
