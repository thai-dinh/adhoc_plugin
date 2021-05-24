import 'dart:async';
import 'dart:collection';

import 'constants.dart';
import 'wrapper_ble.dart';
import 'wrapper_network.dart';
import 'wrapper_wifi.dart';
import '../../appframework/config.dart';
import '../../datalink/exceptions/device_failure.dart';
import '../../datalink/service/adhoc_device.dart';
import '../../datalink/service/adhoc_event.dart';
import '../../datalink/service/constants.dart';
import '../../datalink/utils/msg_adhoc.dart';
import '../../datalink/utils/msg_header.dart';


/// Class acting as an intermediary sub-layer between the lower layer (data-link)
/// and the sub-layer (aodv) related to the routing protocol. It chooses which 
/// wrapper to use to transmit data.
class DataLinkManager {
  late String _ownLabel;
  late List<WrapperNetwork?> _wrappers;
  late HashMap<String, AdHocDevice> _mapAddressDevice;
  late StreamController<AdHocEvent> _controller;

  /// Creates a [DataLinkManager] object.
  /// 
  /// This object is configured according to [config], which contains specific 
  /// configurations.
  DataLinkManager(bool verbose, Config config) {
    this._ownLabel = config.label;
    this._mapAddressDevice = HashMap();
    this._wrappers = List.filled(NB_WRAPPERS, null);
    this._wrappers[BLE] = WrapperBle(verbose, config, _mapAddressDevice);
    this._wrappers[WIFI] = WrapperWifi(verbose, config, _mapAddressDevice);
    this._mapAddressDevice = HashMap();
    this._controller = StreamController<AdHocEvent>.broadcast();
    this._initialize();
    this.checkState();
  }

/*------------------------------Getters & Setters-----------------------------*/

  /// Returns the direct neighbours of the current mobile as a [List] of 
  /// [AdHocDevice].
  List<AdHocDevice> get directNeighbors {
    List<AdHocDevice> neighbors = List.empty(growable: true);

    for (int i = 0; i < NB_WRAPPERS; i++)
      neighbors.addAll(_wrappers[i]!.directNeighbors);

    return neighbors;
  }

    /// Returns the [Stream] of [AdHocEvent] events of lower layers.
  Stream<AdHocEvent> get eventStream => _controller.stream;

/*-------------------------------Public methods-------------------------------*/

  /// Checks the state (enabled/disabled) of the different technologies.
  /// 
  /// Returns the number of technologies enabled.
  int checkState() {
    int enabled = 0;
    for (WrapperNetwork? wrapper in _wrappers) {
      if (wrapper != null && wrapper.enabled)
        enabled++;
    }

    return enabled;
  }


  /// Enables a particular technology.
  /// 
  /// The technology is specified by [type] and it is enabled for [duration] ms.
  void enable(int duration, int type) {
    WrapperNetwork? wrapper = _wrappers[type];
    if (wrapper != null)
      wrapper.enable(duration);
  }


  /// Enables both Bluetooth Low Energy and Wi-Fi technologies.
  void enableAll() {
    for (WrapperNetwork? wrapper in _wrappers) {
      if (wrapper != null)
        enable(3600, wrapper.type);
    }
  }


  /// Disable a particular technology.
  /// 
  /// The technology specified by [type] is disabled.
  void disable(int type) {
    WrapperNetwork? wrapper = _wrappers[type];
    if (wrapper != null && wrapper.enabled)
      wrapper..stopListening()..disable();
  }


  /// Disables all technologies.
  void disableAll() {
    for (WrapperNetwork? wrapper in _wrappers) {
      if (wrapper != null && wrapper.enabled)
        disable(wrapper.type);
    }
  }


  /// Performs a discovery process. 
  /// 
  /// If the Bluetooth Low Energy and Wi-Fi are enabled, the two discoveries are 
  /// performed in parallel. A discovery process lasts for at least 10-12 
  /// seconds.
  void discovery() {
    int enabled = checkState();
    if (enabled == 0)
      throw DeviceFailureException('No wifi and bluetooth connectivity');

    // Both data link communications are enabled
    if (enabled == _wrappers.length) {
      _discovery();
    } else {
      // Discovery depending their status
      for (WrapperNetwork? wrapper in _wrappers) {
        if (wrapper != null && wrapper.enabled)
          wrapper.discovery();
      }
    }
  }


  /// Attempts to connect to a remote peer.
  /// 
  /// The connection to [device] process is done at most [attempts] times.
  Future<void> connect(int attempts, AdHocDevice device) async {
    WrapperNetwork? wrapper = _wrappers[device.type];
    if (wrapper != null)
      await wrapper.connect(attempts, device);
  }


  /// Stop the listening process of incoming connections.
  void stopListening() {
    for (WrapperNetwork? wrapper in _wrappers) {
      if (wrapper!.enabled)
        wrapper.stopListening();
    }
  }


  /// Removes the node from a current Wi-Fi Direct group.
  void removeGroup() {
    WrapperNetwork? wrapper = _wrappers[WIFI];
    if (wrapper != null && wrapper.enabled) {
      (wrapper as WrapperWifi).removeGroup();
    } else {
      throw DeviceFailureException("Wifi is not enabled");
    }
  }


  /// Checks if the current device is the Wi-Fi Direct group owner.
  /// 
  /// Returns true if it is, otherwise false.
  bool isWifiGroupOwner() {
    WrapperNetwork? wrapper = _wrappers[WIFI];
    if (wrapper != null && wrapper.enabled) {
      return (wrapper as WrapperWifi).isGroupOwner;
    } else {
      throw DeviceFailureException("Wifi is not enabled");
    }
  }


  /// Sends a message to a remote peer.
  /// 
  /// The message is specified by [message] and the address by [address].
  void sendMessage(String address, MessageAdHoc message) {
    for (WrapperNetwork? wrapper in _wrappers) {
      if (wrapper != null && wrapper.enabled)
        wrapper.sendMessage(address, message);
    }
  }


  /// Broadcasts a message to all directly connected nodes.
  /// 
  /// The message is specified by [message].
  void broadcast(MessageAdHoc message) {
    for (WrapperNetwork? wrapper in _wrappers) {
      if (wrapper != null && wrapper.enabled)
        wrapper.broadcast(message);
    }
  }


  /// Broadcasts a message to all directly connected nodes.
  /// 
  /// The message payload is set to [object].
  /// 
  /// Returns true if the broadcast is successful, otherwise false.
  Future<bool> broadcastObject(Object object) async {
    bool sent = false;
    for (WrapperNetwork? wrapper in _wrappers) {
      if (wrapper != null && wrapper.enabled) {
        Header header = Header(
          messageType: BROADCAST,
          label: _ownLabel,
          name: await wrapper.getAdapterName(),
          deviceType: wrapper.type,
        );

        if (wrapper.broadcast(MessageAdHoc(header, object)))
          sent = true;
      }
    }

    return sent;
  }


  /// Broadcasts a message to all directly connected nodes except the excluded
  /// node.
  /// 
  /// The message to be broadcast is specified by [message] and the excluded 
  /// node is specified by [excluded].
  void broadcastExcept(MessageAdHoc message, String excluded) {
    for (WrapperNetwork? wrapper in _wrappers) {
      if (wrapper != null && wrapper.enabled)
        wrapper.broadcastExcept(message, excluded);
    }
  }


  /// Broadcasts a message to all directly connected nodes except the excluded
  /// node.
  /// 
  /// The message payload is set to [object] and the excluded node is specified 
  /// by [excluded].
  /// 
  /// Returns true if the broadcast is successful, otherwise false.
  Future<bool> broadcastObjectExcept(Object object, String excluded) async {
    bool sent = false;
    for (WrapperNetwork? wrapper in _wrappers) {
      if (wrapper != null && wrapper.enabled) {
        Header header = Header(
          messageType: BROADCAST,
          label: _ownLabel,
          name: await wrapper.getAdapterName(),
          deviceType: wrapper.type,
        );

        if (wrapper.broadcastExcept(MessageAdHoc(header, object), excluded))
          sent = true;
      }
    }

    return sent;
  }


  /// Gets all the Bluetooth Low Energy devices, which are already paired.
  /// 
  /// Returns a hash map where the key type is a [String] and the value type is
  /// a [AdHocDevice].
  Future<HashMap<String, AdHocDevice>> getPaired() async {
    WrapperNetwork? wrapper = _wrappers[BLE];
    if (wrapper != null && wrapper.enabled)
      return await wrapper.getPaired();
    return HashMap();
  }


  /// Checks if a node is a direct neighbour.
  /// 
  /// The neighbour is identified by [address].
  /// 
  /// Returns true if it is a direct neightbour, otherwise false.
  bool isDirectNeighbors(String address) {
    for (WrapperNetwork? wrapper in _wrappers)
      if (wrapper != null && wrapper.enabled && wrapper.isDirectNeighbors(address))
        return true;
    return false;
  }


  /// Gets the direct neighbours of the current mobile.
  /// 
  /// Returns a [List] of [AdHocDevice], which are filled with direct neighours
  /// nodes regardless of the technology employed.
  List<AdHocDevice> getDirectNeighbors() {
    List<AdHocDevice> devices = List.empty(growable: true);

    for (WrapperNetwork? wrapper in _wrappers) {
      if (wrapper != null && wrapper.enabled)
        devices.addAll(wrapper.directNeighbors);
    }

    return devices;
  }


  /// Checks if a particular technology is enabled.
  /// 
  /// The technology is specified by [type], where a '0' value represents Wi-Fi
  /// and a '1' value Bluetooth Low Energy.
  /// 
  /// Returns true if the specified technology is enabled.
  bool isEnabled(int type) {
    WrapperNetwork? wrapper = _wrappers[type];
    return (wrapper == null) ? false : wrapper.enabled;
  }


  /// Gets a particular adapter name.
  /// 
  /// The technology is specified by [type], where a '0' value represents Wi-Fi
  /// and a '1' value Bluetooth Low Energy.
  /// 
  /// Returns a [String] representing the adapter name of the specified 
  /// technology.
  Future<String> getAdapterName(int type) async {
    WrapperNetwork? wrapper = _wrappers[type];
    if (wrapper != null && wrapper.enabled)
      return await wrapper.getAdapterName();
    return '';
  }


  /// Gets the adapter names.
  /// 
  /// Returns a [HashMap] representing the adapter name of the specified 
  /// technology. The key value are integer, where a '0' value represents Wi-Fi
  /// and a '1' value Bluetooth Low Energy.
  Future<HashMap<int, String>> getActifAdapterNames() async {
    HashMap<int, String> adapterNames = HashMap();

    for (WrapperNetwork? wrapper in _wrappers) {
      if (wrapper != null) {
        String name = await getAdapterName(wrapper.type);
        adapterNames.putIfAbsent(wrapper.type, () => name);
      }
    }

    return adapterNames;
  }


  /// Updates the name of a particular technology.
  /// 
  /// The technology is specified by [type], where a '0' value represents Wi-Fi
  /// and a '1' value Bluetooth Low Energy.
  /// 
  /// The new name is given by [newName].
  /// 
  /// Returns true if it has been set successfully, otherwise false.
  Future<bool> updateAdapterName(int type, String newName) async {
    WrapperNetwork? wrapper = _wrappers[type];
    if (wrapper != null && wrapper.enabled) {
      return await _wrappers[type]!.updateDeviceName(newName);
    } else {
      throw DeviceFailureException('${_typeString(type)} adapter is not enabled');
    }
  }


  /// Resest the adapter name of a particular technology.
  /// 
  /// The technology is specified by [type], where a '0' value represents Wi-Fi
  /// and a '1' value Bluetooth Low Energy.
  void resetAdapterName(int type) {
    WrapperNetwork? wrapper = _wrappers[type];
    if (wrapper != null && wrapper.enabled) {
      wrapper.resetDeviceName();
    } else {
      throw DeviceFailureException('${_typeString(type)} adapter is not enabled');
    }
  }


  /// Disconnects the current node from all remote node.
  void disconnectAll() {
    for (WrapperNetwork? wrapper in _wrappers)
      if (wrapper != null && wrapper.enabled)
        wrapper.disconnectAll();
  }


  /// Disconnects the current node from a specific remote node.
  /// 
  /// The remote node is identified by [remoteAddress].
  void disconnect(String remoteAddress) {
    for (WrapperNetwork? wrapper in _wrappers) {
      if (wrapper != null && wrapper.enabled)
        wrapper.disconnect(remoteAddress);
    }
  }

/*------------------------------Private methods-------------------------------*/

  /// Initializes the listening process of lower layer streams.
  void _initialize() {
    _wrappers[BLE]!.eventStream.listen((event) => _controller.add(event));
    _wrappers[WIFI]!.eventStream.listen((event) => _controller.add(event));
  }


  /// Performs the discovery process in parallel for both technologies.
  void _discovery() {
    for (WrapperNetwork? wrapper in _wrappers) {
      if (wrapper != null && wrapper.enabled)
        wrapper.discovery();
    }

    Timer.periodic(Duration(milliseconds: POOLING_DISCOVERY), (Timer timer) {
      bool finished = true;
      for (WrapperNetwork? wrapper in _wrappers) {
        if (wrapper != null && !wrapper.discoveryCompleted) {
          finished = false;
          break;
        }
      }

      if (finished)
        timer.cancel();
    });

    for (WrapperNetwork? wrapper in _wrappers) {
      if (wrapper != null)
        wrapper.discoveryCompleted = false;
    }
  }


  /// Gets the type of the wrapper.
  /// 
  /// The type is specified by [type].
  /// 
  /// Returns the type of the wrapper as a [String] value.
  String _typeString(int type) {
    switch (type) {
      case BLE:
        return "Ble";
      case WIFI:
        return "Wifi";
      default:
        return "Unknown";
    }
  }
}
