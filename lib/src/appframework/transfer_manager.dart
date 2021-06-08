import 'dart:async';
import 'dart:collection';

import 'package:adhoc_plugin/src/appframework/config.dart';
import 'package:adhoc_plugin/src/appframework/constants.dart';
import 'package:adhoc_plugin/src/appframework/event.dart';
import 'package:adhoc_plugin/src/datalink/exceptions/device_failure.dart';
import 'package:adhoc_plugin/src/datalink/service/adhoc_device.dart';
import 'package:adhoc_plugin/src/datalink/service/constants.dart';
import 'package:adhoc_plugin/src/network/datalinkmanager/constants.dart';
import 'package:adhoc_plugin/src/network/datalinkmanager/datalink_manager.dart';
import 'package:adhoc_plugin/src/presentation/constants.dart';
import 'package:adhoc_plugin/src/presentation/presentation_manager.dart';


/// Class providing high-Level APIs to manage ad hoc networks and network 
/// communications.
class TransferManager {
  final bool _verbose;

  late Config _config;
  late DataLinkManager _datalinkManager;
  late PresentationManager _presentationManager;
  late StreamController<Event> _controller;

  /// Creates a [TransferManager] object.
  /// 
  /// The debug/verbose mode is set if [_verbose] is true.
  /// 
  /// This object is configured according to [config], which contains specific 
  /// configurations.
  TransferManager(this._verbose, {Config? config}) {
    _config = config ?? Config();
    _presentationManager = PresentationManager(_verbose, _config);
    _datalinkManager = _presentationManager.datalinkManager;
    _controller = StreamController.broadcast();
    _initialize();
  }

/*------------------------------Getters & Setters-----------------------------*/

  /// List of direct neighors of this node ([List] of [AdHocDevice]).
  List<AdHocDevice> get directNeighbors => _presentationManager.directNeighbors;

  /// Stream of lower layers ad hoc events represented by [Event].
  Stream<Event> get eventStream => _controller.stream;

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

  /// Stance about joining group formation
  set open(bool state) => _presentationManager.groupController.public = state;

/*-------------------------------Group Methods--------------------------------*/

  /// Creates a secure group.
  /// 
  /// If [labels] is given, then the group init request message is sent to those
  /// particular addresses. Otherwise, the message is broadcasted.
  /// 
  /// Throws a [DeviceFailureException] if the Wi-Fi/Bluetooth adapter is not
  /// enabled.
  void createGroup([List<String>? labels]) {
    if (_datalinkManager.checkState() == 0) {
      throw DeviceFailureException('No wifi and bluetooth connectivity');
    }

    _presentationManager.groupController.createGroup(labels);
  }


  /// Joins an existing secure group.
  /// 
  /// If [label] is given, then the group join request message is sent to that
  /// particular address. Otherwise, the join request message is broadcasted.
  /// 
  /// Throws a [DeviceFailureException] if the Wi-Fi/Bluetooth adapter is not
  /// enabled.
  void joinGroup([String? label]) {
    if (_datalinkManager.checkState() == 0) {
      throw DeviceFailureException('No wifi and bluetooth connectivity');
    }

    _presentationManager.groupController.joinSecureGroup(label);
  }


  /// Leaves an existing secure group.
  /// 
  /// Throws a [DeviceFailureException] if the Wi-Fi/Bluetooth adapter is not
  /// enabled.
  void leaveGroup() {
    if (_datalinkManager.checkState() == 0) {
      throw DeviceFailureException('No wifi and bluetooth connectivity');
    }

    _presentationManager.groupController.leaveSecureGroup();
  }


  /// Sends a confidential message to the secure group members.
  /// 
  /// The payload [data] is encrypted.
  /// 
  /// Throws a [DeviceFailureException] if the Wi-Fi/Bluetooth adapter is not
  /// enabled.
  void sendMessageToGroup(Object data) {
    if (_datalinkManager.checkState() == 0) {
      throw DeviceFailureException('No wifi and bluetooth connectivity');
    }

    _presentationManager.groupController.sendMessageToGroup(data);
  }

/*------------------------------Network Methods------------------------------*/

  /// Sends a message to a remote node.
  /// 
  /// The message payload is set to [data] and the message is sent to the remote
  /// node, which is specified by [destination].
  /// 
  /// Throws a [DeviceFailureException] if the Wi-Fi/Bluetooth adapter is not
  /// enabled.
  void sendMessageTo(Object data, String destination) {
    if (_datalinkManager.checkState() == 0) {
      throw DeviceFailureException('No wifi and bluetooth connectivity');
    }

    _presentationManager.send(data, destination, false);
  }


  /// Sends a message, whose payload is encrypted, to a remote node.
  /// 
  /// The message payload is set to [data] and is encrypted. The message is sent 
  /// to the remote node, which is specified by [destination].
  /// 
  /// Throws a [DeviceFailureException] if the Wi-Fi/Bluetooth adapter is not
  /// enabled.
  void sendEncryptedMessageTo(Object data, String destination) {
    if (_datalinkManager.checkState() == 0) {
      throw DeviceFailureException('No wifi and bluetooth connectivity');
    }

    _presentationManager.send(data, destination, true);
  }


  /// Broadcasts a message to all directly connected nodes.
  /// 
  /// The message payload is set to [data].
  /// 
  /// Returns true upon successful broadcast, otherwise false.
  /// 
  /// Throws a [DeviceFailureException] if the Wi-Fi/Bluetooth adapter is not
  /// enabled.
  Future<bool> broadcast(Object data) async {
    if (_datalinkManager.checkState() == 0) {
      throw DeviceFailureException('No wifi and bluetooth connectivity');
    }

    return await _presentationManager.broadcast(data, false);
  }


  /// Broadcasts a message, whose payload is encrypted, to all directly 
  /// connected nodes.
  /// 
  /// The message payload is set to [data] and is encrypted.
  /// 
  /// Returns true upon successful broadcast, otherwise false.
  /// 
  /// Throws a [DeviceFailureException] if the Wi-Fi/Bluetooth adapter is not
  /// enabled.
  Future<bool> encryptedBroadcast(Object data) async {
    if (_datalinkManager.checkState() == 0) {
      throw DeviceFailureException('No wifi and bluetooth connectivity');
    }

    return await _presentationManager.broadcast(data, true);
  }


  /// Broadcasts a message to all directly connected nodes except the excluded
  /// one.
  /// 
  /// The message payload is set to [data].
  /// 
  /// The node specified by [excluded] is not included in the broadcast.
  /// 
  /// Returns true upon successful broadcast, otherwise false.
  /// 
  /// Throws a [DeviceFailureException] if the Wi-Fi/Bluetooth adapter is not
  /// enabled.
  Future<bool> broadcastExcept(Object data, AdHocDevice excluded) async {
    if (_datalinkManager.checkState() == 0) {
      throw DeviceFailureException('No wifi and bluetooth connectivity');
    }

    return await _presentationManager.broadcastExcept(data, excluded.label!, false);
  }


  /// Broadcasts a message, whose payload is encrypted, to all directly 
  /// connected nodes except the excluded one.
  /// 
  /// The message payload is set to [data] and is encrypted.
  /// 
  /// The node specified by [excluded] is not included in the broadcast.
  /// 
  /// Returns true upon successful broadcast, otherwise false.
  /// 
  /// Throws a [DeviceFailureException] if the Wi-Fi/Bluetooth adapter is not
  /// enabled.
  Future<bool> encryptedBroadcastExcept(Object data, AdHocDevice excluded) async {
    if (_datalinkManager.checkState() == 0) {
      throw DeviceFailureException('No wifi and bluetooth connectivity');
    }

    return await _presentationManager.broadcastExcept(data, excluded.label!, true);
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
  /// 
  /// Throws a [DeviceFailureException] if the Wi-Fi/Bluetooth adapter is not
  /// enabled.
  Future<void> connect(AdHocDevice device, [int? attempts]) async {        
    if (_datalinkManager.checkState() == 0) {
      throw DeviceFailureException('No wifi and bluetooth connectivity');
    }

    await _datalinkManager.connect(attempts ?? 1, device);
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


  /// Initialises the underlying Wi-Fi data structures.
  /// 
  /// Note: It is not possible to enable/disable Wi-Fi starting with Build.VERSION_CODES#Q.
  /// https://developer.android.com/reference/android/net/wifi/WifiManager#setWifiEnabled(boolean)
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

/*------------------------------Private Methods------------------------------*/

  /// Listens to lower layers event stream.
  /// 
  /// Its main purpose is to encapsulate the data into Event object.
  void _initialize() {
    _presentationManager.eventStream.listen((event) {
      AdHocDevice? device;
      late Object data;

      switch (event.type) {
        case DEVICE_DISCOVERED:
          device = event.payload as AdHocDevice;

          _controller.add(Event(AdHocType.onDeviceDiscovered, device: device));
          break;

        case DISCOVERY_START:
          _controller.add(Event(AdHocType.onDiscoveryStarted));
          break;

        case DISCOVERY_END:
          data = event.payload as HashMap<String, AdHocDevice>;

          _controller.add(Event(AdHocType.onDiscoveryCompleted, data: data));
          break;

        case DATA_RECEIVED:
          var payload = event.payload as List<dynamic>;

          device = payload.first as AdHocDevice;
          data = payload.last as Object;

          _controller.add(Event(AdHocType.onDataReceived, device: device, data: data));
          break;

        case FORWARD_DATA:
          var payload = event.payload as List<dynamic>;

          device = payload.first as AdHocDevice;
          data = payload.last as Object;

          _controller.add(Event(AdHocType.onForwardData, device: device, data: data));
          break;

        case CONNECTION_PERFORMED:
          device = event.payload as AdHocDevice;

          _controller.add(Event(AdHocType.onConnection, device: device));
          break;

        case CONNECTION_ABORTED:
          device = event.payload as AdHocDevice;

          _controller.add(Event(AdHocType.onConnectionClosed, device: device));
          break;

        case INTERNAL_EXCEPTION:
          data = event.payload as Exception;

          _controller.add(Event(AdHocType.onInternalException, data: data));
          break;

        case GROUP_STATUS:
          data = event.payload as int;

          _controller.add(Event(AdHocType.onGroupInfo, data: data));
          break;

        case GROUP_DATA:
          var payload = event.payload as List<dynamic>;

          device = payload.first as AdHocDevice;
          data = payload.last as Object;

          _controller.add(Event(AdHocType.onGroupDataReceived, device: device, data: data));
          break;

        default:
      }
    });
  }
}
