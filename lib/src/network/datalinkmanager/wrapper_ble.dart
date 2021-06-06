import 'dart:async';
import 'dart:collection';

import 'package:adhoc_plugin/src/appframework/config.dart';
import 'package:adhoc_plugin/src/datalink/ble/ble_adhoc_device.dart';
import 'package:adhoc_plugin/src/datalink/ble/ble_adhoc_manager.dart';
import 'package:adhoc_plugin/src/datalink/ble/ble_client.dart';
import 'package:adhoc_plugin/src/datalink/ble/ble_server.dart';
import 'package:adhoc_plugin/src/datalink/ble/ble_services.dart';
import 'package:adhoc_plugin/src/datalink/exceptions/device_failure.dart';
import 'package:adhoc_plugin/src/datalink/service/adhoc_device.dart';
import 'package:adhoc_plugin/src/datalink/service/adhoc_event.dart';
import 'package:adhoc_plugin/src/datalink/service/constants.dart';
import 'package:adhoc_plugin/src/datalink/service/service.dart';
import 'package:adhoc_plugin/src/datalink/service/service_client.dart';
import 'package:adhoc_plugin/src/datalink/utils/identifier.dart';
import 'package:adhoc_plugin/src/datalink/utils/msg_adhoc.dart';
import 'package:adhoc_plugin/src/datalink/utils/msg_header.dart';
import 'package:adhoc_plugin/src/datalink/utils/utils.dart';
import 'package:adhoc_plugin/src/network/datalinkmanager/constants.dart';
import 'package:adhoc_plugin/src/network/datalinkmanager/flood_msg.dart';
import 'package:adhoc_plugin/src/network/datalinkmanager/network_manager.dart';
import 'package:adhoc_plugin/src/network/datalinkmanager/wrapper_network.dart';

/// Class inheriting the abstract wrapper class [WrapperNetwork] and managing
/// all communications related to Bluetooth Low Energy.
///
/// NOTE: Most of the following source code has been borrowed and adapted from
/// the original codebase provided by Gaulthier Gain, which can be found at:
/// https://github.com/gaulthiergain/AdHocLib
class WrapperBle extends WrapperNetwork {
  static const String TAG = "[WrapperBle]";

  String? _ownBleUUID;
  StreamSubscription<AdHocEvent>? _eventSub;

  late BleAdHocManager _bleAdHocManager;

  /// Creates a [WrapperBle] object.
  ///
  /// The debug/verbose mode is set if [verbose] is true.
  ///
  /// The given hash map [mapMacDevices] is used to map a MAC address entry to
  /// an [AdHocDevice] object.
  WrapperBle(bool verbose, Config config, HashMap<Identifier, AdHocDevice> mapMacDevices) 
    : super(verbose, config, mapMacDevices) {
    type = BLE;
    init(verbose, null);
  }

/*------------------------------Override methods------------------------------*/

  /// Initializes internal parameters.
  ///
  /// The debug/verbose mode is set if [verbose] is true.
  ///
  /// This object is configured according to the parameters in [config] if it
  /// is given, otherwise the default settings are used.
  @override
  Future<void> init(bool verbose, Config? config) async {
    if (await BleServices.isBleAdapterEnabled()) {
      _bleAdHocManager = BleAdHocManager(verbose);
      ownName = await BleServices.bleAdapterName;
      _listenServer();
      _initialize();
      enabled = true;
    } else {
      enabled = false;
    }
  }

  /// Enables the Bluetooth of the device as well as sets it in discovery mode.
  ///
  /// The discovery mode lasts for [duration] ms.
  ///
  /// Throws an [BadDurationException] if the given duration exceeds 3600
  /// seconds or is negative.
  @override
  void enable(int duration) async {
    if (!enabled) {
      _bleAdHocManager = BleAdHocManager(verbose);
      await _bleAdHocManager.enable();
      _bleAdHocManager.enableDiscovery(duration);
      ownName = await BleServices.bleAdapterName;
      _listenServer();
      _initialize();
      enabled = true;
    } else {
      _bleAdHocManager.enableDiscovery(duration);
    }
  }

  /// Disables the Bluetooth adapter of the device.
  @override
  void disable() {
    mapAddrNetwork.clear();
    neighbors.clear();

    _bleAdHocManager.disable();

    if (_eventSub != null) {
      _eventSub!.cancel();
      _eventSub = null;
    }

    isListening = false;
    isDiscovering = false;

    enabled = false;
  }

  /// Performs a Bluetooth Low Energy discovery process.
  ///
  /// If the Bluetooth Low Energy and Wi-Fi are enabled, the two discoveries are
  /// performed in parallel. A discovery process lasts for at least 10-12 seconds.
  @override
  void discovery() {
    if (isDiscovering) {
      return;
    }

    _eventSub!.resume();
    _bleAdHocManager.discovery();
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
    var bleAdHocDevice = mapMacDevices[device.mac] as BleAdHocDevice?;
    if (bleAdHocDevice != null) {
      if (!serviceServer.containConnection(bleAdHocDevice.mac.ble)) {
        await _connect(attempts, bleAdHocDevice);
      } else {
        throw DeviceFailureException('${device.name} (${device.mac.ble}) is already connected');
      }
    }
  }

  /// Stops the listening process of incoming connections.
  @override
  void stopListening() {
    super.stopListening();
    serviceServer.stopListening();
  }

  /// Gets all the Bluetooth devices which are already paired.
  ///
  /// Returns a hash map (<[String], [AdHocDevice]>) containing the paired
  /// devices.
  @override
  Future<HashMap<String, AdHocDevice>> getPaired() async {
    if (!await BleServices.isBleAdapterEnabled()) {
      return HashMap();
    }

    var paired = HashMap<String, BleAdHocDevice>();
    Map pairedDevices = await _bleAdHocManager.getPairedDevices();
    pairedDevices.forEach((mac, bleAdHocDevice) {
      paired.putIfAbsent(mac as String, () => bleAdHocDevice as BleAdHocDevice);
    });

    return paired;
  }

  /// Gets the Bluetooth adapter name.
  ///
  /// Returns a [String] representing the adapter name.
  @override
  Future<String> getAdapterName() async {
    final String? name = await _bleAdHocManager.adapterName;
    return name ?? '';
  }

  /// Updates the Bluetooth adapter name of the device with [name].
  ///
  /// Returns true if the name is successfully set, otherwise false.
  @override
  Future<bool> updateDeviceName(String name) async {
    final bool? result = await _bleAdHocManager.updateDeviceName(name);
    return result ?? false;
  }

  /// Resets the Bluetooth adapter name of the device.
  ///
  /// Returns true if the name is successfully reset, otherwise false.
  @override
  Future<bool> resetDeviceName() async {
    final bool? result = await _bleAdHocManager.resetDeviceName();
    return result ?? false;
  }

/*------------------------------Private methods-------------------------------*/

  /// Initializes the listening process of the under layer streams.
  ///
  /// In this case, the streams contains [AdHocEvent] object related to the BLE
  /// discovery process.
  void _initialize() {
    if (isListening) {
      return;
    }

    isListening = true;
    // Listen to stream of ad hoc events
    _eventSub = _bleAdHocManager.eventStream.listen((event) {
      // Notify upper layer of discovery event
      controller.add(event);

      switch (event.type) {
        case DEVICE_DISCOVERED:
          // Process discovered potential peer
          var device = event.payload as BleAdHocDevice;
          // Add device to hash map
          mapMacDevices.putIfAbsent(device.mac, () {
            if (verbose) {
              log(TAG, "Add " + device.mac.ble + " into mapMacDevices");
            }

            return device;
          });
          break;

        case DISCOVERY_END:
          // Process end of discovery process
          if (verbose) log(TAG, 'Discovery end');
          (event.payload as Map).forEach((mac, device) {
            // Add device to hash map
            mapMacDevices.putIfAbsent(Identifier(ble: mac as String), () {
              if (verbose) log(TAG, "Add " + mac + " into mapMacDevices");
              return device as BleAdHocDevice;
            });
          });

          discoveryCompleted = true;
          isDiscovering = false;
          _eventSub!.pause();
          break;

        default:
      }
    });

    _eventSub!.pause();
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
          var data = event.payload as List<dynamic>;
          var mac = data[0] as String;
          var uuid = data[1] as String;
          var serviceType = data[2] as int;
          if (serviceType == SERVER) {
            break;
          }

          // Store remote node's NetworkManager
          mapAddrNetwork.putIfAbsent(
            uuid,
            () => NetworkManager(
              (msg) async {
                msg.header.address = _ownBleUUID;
                msg.header.deviceType = BLE;
                (service as ServiceClient).send(msg);
              },
              () => (service as ServiceClient).disconnect()
            ),
          );

          // Send message control containing MAC address of the remote node
          (service as ServiceClient).send(MessageAdHoc(
            Header(
              messageType: CONNECT_SERVER,
              label: ownLabel,
              name: ownName,
              mac: ownMac,
              address: _ownBleUUID,
              deviceType: BLE
            ),
            mac
          ));
          break;

        case CONNECTION_ABORTED:
          // Process remote connection aborted
          connectionClosed(Identifier(ble: event.payload as String));
          break;

        case CONNECTION_FAILED:
          // Notify upper layer of connection failed
          controller.add(event);
          break;

        case INTERNAL_EXCEPTION:
          // Notify upper layer of an exception occured at data-link layer
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
    serviceServer = BleServer(verbose)..listen();

    /// Initialize the underlayer server service
    _bleAdHocManager.initialize();
    // Listen to the ad hoc events of the network (msg received, ...)
    _onEvent(serviceServer);
  }

  /// Connects to a remote Ble-capable peer.
  ///
  /// The remote peer is specified by [device] and it is tried [attempts] times.
  Future<void> _connect(int attempts, final BleAdHocDevice device) async {
    final bleClient = BleClient(verbose, device, attempts, timeOut);
    // Listen to the ad hoc events of the network (msg received, ...)
    _onEvent(bleClient);
    // Connect to the remote node
    await bleClient.connect();
  }

  /// Processes messages received from remote nodes.
  ///
  /// The [message] represents a message send through the network.
  void _processMsgReceived(final MessageAdHoc message) {
    print(message.toString());
    switch (message.header.messageType) {
      case CONNECT_SERVER:
        // Recover this own node MAC and BLE address
        var mac = message.header.mac.ble;
        ownMac = Identifier(ble: message.pdu as String);
        _ownBleUUID = BLUETOOTHLE_UUID + ownMac.ble.replaceAll(RegExp(':'), '');
        _ownBleUUID = _ownBleUUID!.toLowerCase();

        // Notify upper layer of the recovery of this node's information
        controller.add(AdHocEvent(DEVICE_INFO_BLE, [ownMac.ble, ownName]));

        // Respond to the control message received
        serviceServer.send(
          MessageAdHoc(
            Header(
              messageType: CONNECT_CLIENT,
              label: ownLabel,
              name: ownName,
              mac: ownMac,
              address: _ownBleUUID,
              deviceType: type
            ),
            mac,
          ),
          mac,
        );

        // Process received message from remote nodes
        receivedPeerMessage(message.header,
          NetworkManager(
            (msg) async {
              msg.header.address = _ownBleUUID;
              msg.header.deviceType = BLE;
              await serviceServer.send(msg, mac);
            }, 
            () => serviceServer.cancelConnection(mac)
          ),
        );
        break;

      case CONNECT_CLIENT:
        // Recover this own node MAC and BLE address
        ownMac = Identifier(ble: message.pdu as String);
        _ownBleUUID = BLUETOOTHLE_UUID + ownMac.ble.replaceAll(RegExp(':'), '').toLowerCase();

        // Notify upper layer of the recovery of this node's information
        controller.add(AdHocEvent(DEVICE_INFO_BLE, [ownMac.ble, ownName]));

        // Process received message from remote nodes
        receivedPeerMessage(message.header, mapAddrNetwork[message.header.address]!);
        break;

      case CONNECT_BROADCAST:
        var floodMsg = FloodMsg.fromJson((message.pdu as Map) as Map<String, dynamic>);
        // If the flooding option is enabled, then flood the connection event
        if (checkFloodEvent(floodMsg.id)) {
          // Rebroadcast the message to this node direct neighbors
          broadcastExcept(message, message.header.label);

          // Get message information
          HashSet<AdHocDevice?> hashSet = floodMsg.devices;
          for (var device in hashSet) {
            if (device!.label != ownLabel && !setRemoteDevices.contains(device) &&
                !isDirectNeighbor(device.label!)) {

              // Notify upper layer of a new remote connection established
              controller.add(AdHocEvent(CONNECTION_PERFORMED, device));

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
          var header = message.header;
          // Get the sender information
          var device = AdHocDevice(
            label: header.label,
            name: header.name,
            mac: header.mac,
            type: header.deviceType!
          );

          // Notify upper layer of a remote connection closed
          controller.add(AdHocEvent(CONNECTION_ABORTED, device));

          // Update set
          if (setRemoteDevices.contains(device)) {
            setRemoteDevices.remove(device);
          }
        }
        break;

      case BROADCAST:
        // Get the header of the message received
        var header = message.header;
        // Get the sender information
        var device = AdHocDevice(
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
