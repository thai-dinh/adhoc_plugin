import 'dart:async';
import 'dart:collection';

import 'constants.dart';
import 'flood_msg.dart';
import 'network_manager.dart';
import 'wrapper_network.dart';
import '../../appframework/config.dart';
import '../../datalink/exceptions/bad_duration.dart';
import '../../datalink/exceptions/device_failure.dart';
import '../../datalink/service/adhoc_device.dart';
import '../../datalink/service/adhoc_event.dart';
import '../../datalink/service/constants.dart';
import '../../datalink/service/service.dart';
import '../../datalink/service/service_client.dart';
import '../../datalink/utils/identifier.dart';
import '../../datalink/utils/msg_adhoc.dart';
import '../../datalink/utils/msg_header.dart';
import '../../datalink/utils/utils.dart';
import '../../datalink/wifi/wifi_adhoc_device.dart';
import '../../datalink/wifi/wifi_adhoc_manager.dart';
import '../../datalink/wifi/wifi_client.dart';
import '../../datalink/wifi/wifi_server.dart';


/// Class inheriting the abstract class [WrapperNetwork] and manages all 
/// communications related to Wi-Fi Direct.
class WrapperWifi extends WrapperNetwork {
  static const String TAG = "[WrapperWifi]";

  String? _ownIPAddress;
  String? _groupOwnerAddr;

  late int _serverPort;
  late bool _isConnecting;
  late bool _isGroupOwner;
  late WifiAdHocManager _wifiManager;
  late HashMap<String?, String?> _mapIPAddressMac;

  /// Creates a [WrapperWifi] object.
  /// 
  /// The debug/verbose mode is set if [verbose] is true.
  /// 
  /// The given hash map [mapMacDevices] is used to map a MAC address entry to 
  /// an [AdHocDevice] object.
  WrapperWifi(
    bool verbose, Config config, HashMap<Identifier, AdHocDevice> mapMacDevices
  ) : super(verbose, config, mapMacDevices) {
    this.type = WIFI;
    this._isConnecting = false;
    this._isGroupOwner = false;
    this._mapIPAddressMac = HashMap();
    this.init(verbose, config);
  }

/*------------------------------Getters & Setters-----------------------------*/

  /// Returns whether this node is the group owner or not.
  bool get isGroupOwner => _isGroupOwner;

/*------------------------------Override methods------------------------------*/

  /// Initializes internal parameters.
  /// 
  /// The debug/verbose mode is set if [verbose] is true.
  /// 
  /// This object is configured according to the parameters in [config] if it
  /// is given, otherwise the default settings are used.
  @override
  Future<void> init(bool verbose, Config? config) async {
    _serverPort = config!.serverPort;

    if (await WifiAdHocManager.isWifiEnabled()) {
      this._wifiManager = WifiAdHocManager(verbose);
      this._wifiManager.initialize();
      this._isGroupOwner = false;
      this.ownName = _wifiManager.adapterName;
      this._initialize();
      this.enabled = true;
    } else {
      this.enabled = false;
    }
  }


  /// Initializes Wifi wrapper parameters.
  /// 
  /// Throws an [BadDurationException] if the given duration exceeds 3600 
  /// seconds or is negative.
  /// 
  /// Note: It is not possible to enable/disable Wi-Fi starting with 
  /// Build.VERSION_CODES#Q.
  /// 
  /// https://developer.android.com/reference/android/net/wifi/WifiManager#setWifiEnabled(boolean)
  @override
  void enable(int duration) {
    if (duration < 0 || duration > 3600) {
      throw BadDurationException(
        'Duration must be between 0 and 3600 second(s)'
      );
    }

    _wifiManager = WifiAdHocManager(verbose);
    _wifiManager.initialize();
    _initialize();
    enabled = true;
  }


  /// Clears the data structure of the wrapper.
  @override 
  void disable() {
    mapAddrNetwork.clear();
    neighbors.clear();

    enabled = false;
  }


  /// Performs a Wi-Fi Direct discovery process. 
  /// 
  /// If the Bluetooth Low Energy and Wi-Fi are enabled, the two discoveries are 
  /// performed in parallel. A discovery process lasts for at least 10-12 seconds.
  @override
  void discovery() {
    if (isDiscovering)
      return;

    _wifiManager.discovery();
    isDiscovering = true;
  }


  /// Connects to a remote peer.
  /// 
  /// The remote peer is specified by [device] and the connection attempts is 
  /// set to [attempts].
  /// 
  /// Throws a [DeviceFailureException] if this device is alreay connected to
  /// the remote peer.
  @override
  Future<void> connect(int attempts, AdHocDevice device) async {
    WifiAdHocDevice? wifiAdHocDevice = mapMacDevices[device.mac] as WifiAdHocDevice?;
    if (wifiAdHocDevice != null) {
      this.attempts = attempts;
      await _wifiManager.connect(device.mac.wifi);
    } else {
        throw DeviceFailureException(
          '${device.name} (${device.mac.wifi}) is already connected'
        );
      }
  }


  /// Stops the listening process of incoming connections.
  @override
  void stopListening() {
    super.stopListening();
    serviceServer.stopListening();
    isListening = false;
  }


  /// Not used in Wi-Fi direct context.
  @override
  Future<HashMap<String, AdHocDevice>> getPaired() async => HashMap();


  /// Gets the Wi-Fi adapter name.
  /// 
  /// Returns a [String] representing the adapter name.
  @override
  Future<String> getAdapterName() async {
    final String? name = _wifiManager.adapterName;
    return name == null ? '' : name;
  }


  /// Updates the Wi-Fi adapter name of the device with [name].
  /// 
  /// Returns true if the name is successfully set, otherwise false.
  @override
  Future<bool> updateDeviceName(final String name) async {
    final bool? result = await _wifiManager.updateDeviceName(name);
    return result == null ? false : result ;
  }


  /// Resets the Wi-Fi adapter name of the device.
  /// 
  /// Returns true if the name is successfully reset, otherwise false.
  @override
  Future<bool> resetDeviceName() async {
    final bool? result = await _wifiManager.resetDeviceName();
    return result == null ? false : result ;
  }

/*-------------------------------Public methods-------------------------------*/

  //// Removes the node from a current Wi-Fi Direct group.
  void removeGroup() {
    _mapIPAddressMac.forEach((address, mac) async {
      await serviceServer.cancelConnection(mac!);
    });

    serviceServer.activeConnections.clear();

    WifiAdHocManager.removeGroup();
  }


  /// Checks if the current device is the Wi-Fi Direct group owner.
  /// 
  /// Returns true if it is, otherwise false.
  bool isWifiGroupOwner() => _isGroupOwner;

/*------------------------------Private methods-------------------------------*/

  /// Initializes the listening process of lower layer notification streams.
  void _initialize() {
    _wifiManager.eventStream.listen((AdHocEvent event) {
      switch (event.type) {
        case DEVICE_INFO_WIFI:
          // Listen to the Wi-Fi info device changes
          List<String?> info = (event.payload as List<dynamic>).cast<String?>();
          _ownIPAddress = info[0] == null ? '' : info[0]!;
          ownMac = Identifier(wifi: info[1] == null ? '' : info[1]!);
          break;

        case DEVICE_DISCOVERED:
          // Process discovered potential peer
          WifiAdHocDevice device = event.payload as WifiAdHocDevice;

          // Add device to hash map
          mapMacDevices.putIfAbsent(device.mac, () {
            if (verbose) log(TAG, "Add " + device.mac.wifi + " into mapMacDevices");
            return device;
          });

          // Notify upper layer of a discovered device event
          controller.add(event);
          break;

        case DISCOVERY_END:
          // Process end of discovery process
          if (verbose) log(TAG, 'Discovery end');
          (event.payload as Map<String, WifiAdHocDevice>).forEach((mac, device) {
            // Add device to hash map
            mapMacDevices.putIfAbsent(Identifier(wifi: mac), () {
              if (verbose) log(TAG, "Add " + mac + " into mapMacDevices");
              return device;
            });
          });

          discoveryCompleted = true;
          isDiscovering = false;

          // Notify upper layer of discovery end event
          controller.add(event);
          break;

        case CONNECTION_INFORMATION:
          // Process Wi-Fi connection process
          List<dynamic> info = event.payload as List<dynamic>;
          bool isConnected = info[0];
          bool isGroupOwner = info[1];
          String groupOwnerAddress = info[2];

          _isGroupOwner = isGroupOwner;
          // If a group has been successfully formed and this node is the group 
          // owner, then listen to incoming connections
          if (isConnected && _isGroupOwner) {
            _groupOwnerAddr = _ownIPAddress = groupOwnerAddress;
            if (!isListening) {
              // Start listening server
              _listenServer();
              isListening = true;
            }
          } else if (isConnected && !_isGroupOwner) {
            // This node is not the group owner, then tries to join the group
            _groupOwnerAddr = groupOwnerAddress;
            if (!_isConnecting) {
              _connect(_serverPort);
              _isConnecting = true;
            }
          }
          break;

        default:
          // Forward lower laye event to upper layer
          controller.add(event);
      }
    });
  }


  /// Processes the [AdHocEvent] according to the given service.
  /// 
  /// A service can be of type [ServiceClient] or [ServiceServer].
  void _onEvent(Service service) {
    // Listen to stream of ad hoc events
    service.eventStream.listen((event) async { 
      switch (event.type) {
        case MESSAGE_RECEIVED:
          // Process message received
          _processMsgReceived(event.payload as MessageAdHoc);
          break;

        case CONNECTION_PERFORMED:
          // Process connection establishment
          if (_ownIPAddress == _groupOwnerAddr)
            break;

          String? remoteAddress = event.payload as String?;
          // Save remote node's NetworkManager
          mapAddrNetwork.putIfAbsent(
            remoteAddress!,
            () => NetworkManager(
              (MessageAdHoc msg) async {
                msg.header.address = _ownIPAddress;
                msg.header.deviceType = WIFI;
                (service as ServiceClient).send(msg);
              }, 
              () => (service as ServiceClient).disconnect()
            )
          );

          // Update own name
          ownName = _wifiManager.adapterName;

          // Notify upper layer of Wi-Fi info of this device changed
          controller.add(AdHocEvent(DEVICE_INFO_WIFI, [ownMac.wifi, ownName]));

          // Send control message
          (service as ServiceClient).send(
            MessageAdHoc(
              Header(
                messageType: CONNECT_SERVER,
                label: ownLabel,
                name: ownName,
                mac: ownMac,
                address: _ownIPAddress,
                deviceType: WIFI
              ),
              null,
            )
          );
          break;

        case CONNECTION_ABORTED:
          // Process remote connection aborted
          connectionClosed(Identifier(wifi: _mapIPAddressMac[event.payload as String]!));
          break;

        case CONNECTION_EXCEPTION:
          // Notify upper layer of an exception occured at lower layers
          controller.add(AdHocEvent(INTERNAL_EXCEPTION, event.payload));
          break;

        default:
      }
    });
  }


  /// Starts the server listening process of incoming connections or messages
  /// received.
  void _listenServer() {
    /// Start server listening 
    serviceServer = WifiServer(verbose)..listen(_ownIPAddress, _serverPort);
    // Listen to the ad hoc events of the network (msg received, ...)
    _onEvent(serviceServer);
  }



  void _connect(int remotePort) async {
    final wifiClient = 
      WifiClient(verbose, remotePort, _groupOwnerAddr!, attempts, timeOut);
    _onEvent(wifiClient);
    await wifiClient.connect();
  }


  /// Processes messages received from remote nodes.
  /// 
  /// The [message] represents a message send through the network.
  void _processMsgReceived(MessageAdHoc message) async {
    switch (message.header.messageType) {
      case CONNECT_SERVER:
        // Save the mapping of remote IP address with its remote MAC address
        String? remoteAddress = message.header.address;
        _mapIPAddressMac.putIfAbsent(
          remoteAddress, () => message.header.mac.wifi
        );

        // Update own name
        ownName = _wifiManager.adapterName;

        // Notify upper layer of Wi-Fi info of this device changed
        controller.add(AdHocEvent(DEVICE_INFO_WIFI, [ownMac.wifi, ownName]));

        // Send control message
        serviceServer.send(
          MessageAdHoc(
            Header(
              messageType: CONNECT_CLIENT,
              label: ownLabel,
              name: ownName,
              mac: ownMac,
              address: _ownIPAddress,
              deviceType: type
            ),
            null,
          ),
          remoteAddress!
        );

        // Process message received from a remote peer
        receivedPeerMessage(
          message.header,
          NetworkManager(
            (MessageAdHoc msg) async {
              msg.header.address = _ownIPAddress;
              msg.header.deviceType = WIFI;
              serviceServer.send(msg, remoteAddress);
            },
            () => serviceServer.cancelConnection(remoteAddress)
          )
        );
        break;

      case CONNECT_CLIENT:
        // Save the mapping of remote IP address with its remote MAC address
        _mapIPAddressMac.putIfAbsent(
          message.header.address, () => message.header.mac.wifi
        );

        // Save remote node's NetworkManager
        NetworkManager? network = mapAddrNetwork[message.header.address];
        
        // Process message received from a remote peer
        receivedPeerMessage(message.header, network!);
        break;

      case CONNECT_BROADCAST:
        FloodMsg floodMsg = FloodMsg.fromJson((message.pdu as Map) as Map<String, dynamic>);
        // If the flooding option is enabled, then flood the connection event
        if (checkFloodEvent(floodMsg.id)) {
          // Rebroadcast the message to this node direct neighbors
          broadcastExcept(message, message.header.label);

          // Get message information
          HashSet<AdHocDevice?> hashSet = floodMsg.devices;
          for (AdHocDevice? device in hashSet) {
            if (device!.label != ownLabel && !setRemoteDevices.contains(device)
              && !isDirectNeighbor(device.label!)
            ) {
              // Notify upper layer of a new remote connection established
              controller.add(AdHocEvent(CONNECTION_EVENT, device));

              setRemoteDevices.add(device);
            }
          }
        }
        break;

      case DISCONNECT_BROADCAST:
        if (checkFloodEvent(message.pdu as String)) {
          // Rebroadcast the message to this node direct neighbors
          broadcastExcept(message, message.header.label);

          // Get the header of the message received
          Header header = message.header;
          // Get the sender information
          AdHocDevice device = AdHocDevice(
            label: header.label,
            name: header.name,
            mac: header.mac,
            type: type
          );

          // Notify upper layer of a remote connection closed
          controller.add(AdHocEvent(DISCONNECTION_EVENT, device));

          // Update set
          if (setRemoteDevices.contains(device))
            setRemoteDevices.remove(device);
        }
        break;

      case BROADCAST:
        // Get the header of the message received
        Header header = message.header;
        // Get the sender information
        AdHocDevice device = AdHocDevice(
          label: header.label,
          name: header.name,
          mac: header.mac,
          type: header.deviceType!
        );

        // Notify upper layer of a message received that contains data
        controller.add(AdHocEvent(DATA_RECEIVED, [device, message.pdu]));
        break;

      default:
        // Forward a message to upper layers
        controller.add(AdHocEvent(MESSAGE_EVENT, message));
    }
  }
}
