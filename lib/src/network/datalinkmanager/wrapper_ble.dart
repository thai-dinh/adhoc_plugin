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
import 'package:adhoc_plugin/src/datalink/utils/msg_adhoc.dart';
import 'package:adhoc_plugin/src/datalink/utils/msg_header.dart';
import 'package:adhoc_plugin/src/datalink/utils/utils.dart';
import 'package:adhoc_plugin/src/network/datalinkmanager/constants.dart';
import 'package:adhoc_plugin/src/network/datalinkmanager/flood_msg.dart';
import 'package:adhoc_plugin/src/network/datalinkmanager/network_manager.dart';
import 'package:adhoc_plugin/src/network/datalinkmanager/wrapper_network.dart';


/// Class inheriting the abstract class [WrapperNetwork] and manages all 
/// communications related to Bluetooth Low Energy
class WrapperBle extends WrapperNetwork {
  static const String TAG = "[WrapperBle]";

  String? _ownBleUUID;

  late bool _isDiscovering;
  late bool _isInitialized;
  late BleAdHocManager _bleAdHocManager;
  late StreamSubscription<AdHocEvent> _eventSub;

  /// Default constructor
  /// 
  /// 
  WrapperBle(
    bool verbose, Config config, HashMap<String?, AdHocDevice?> mapMacDevices
  ) : super(verbose, config, mapMacDevices) {
    this._isDiscovering = false;
    this._isInitialized = false;
    this.ownMac = '';
    this.type = BLE;
    this.init(verbose, null);
  }

/*------------------------------Override methods------------------------------*/

  ///
  @override
  Future<void> init(bool verbose, Config? config) async {
    if (await BleServices.isBleAdapterEnabled()) {
      this._bleAdHocManager = BleAdHocManager(verbose);
      this._bleAdHocManager.enableDiscovery(3600); // TODO
      this.ownName = await BleServices.bleAdapterName;
      this._listenServer();
      this._initialize();
      this.enabled = true;
    } else {
      this.enabled = false;
    }
  }


  ///
  @override
  void enable(int duration) async {
    if (!enabled) {
      this._bleAdHocManager = BleAdHocManager(verbose);
      await _bleAdHocManager.enable();
      this._bleAdHocManager.enableDiscovery(duration);
      this.ownName = await BleServices.bleAdapterName;
      this._listenServer();
      this._initialize();
      this.enabled = true;
    } else {
      this._bleAdHocManager.enableDiscovery(duration);
    }
  }


  ///
  @override
  void disable() {
    mapAddrNetwork.clear();
    neighbors.clear();

    _bleAdHocManager.disable();

    enabled = false;
  }


  ///
  @override
  void discovery() {
    if (_isDiscovering)
      return;

    _eventSub.resume();
    _bleAdHocManager.discovery();
    _isDiscovering = true;
  }


  ///
  @override
  Future<void> connect(int attempts, AdHocDevice device) async {
    BleAdHocDevice? bleAdHocDevice = mapMacDevices[device.mac] as BleAdHocDevice?;
    if (bleAdHocDevice != null) {
      if (!serviceServer.containConnection(bleAdHocDevice.mac!)) {
        await _connect(attempts, bleAdHocDevice);
      } else {
        throw DeviceFailureException(
          device.name! + "(" + device.mac! + ") is already connected"
        );
      }
    }
  }


  ///
  @override
  void stopListening() => serviceServer.stopListening();


  ///
  @override
  Future<HashMap<String?, AdHocDevice>?> getPaired() async {
    if (!await BleServices.isBleAdapterEnabled())
      return null;

    HashMap<String?, BleAdHocDevice> paired = HashMap();
    Map pairedDevices = await _bleAdHocManager.getPairedDevices();
    pairedDevices.forEach((macAddress, bleAdHocDevice) {
      paired.putIfAbsent(macAddress, () => bleAdHocDevice);
    });

    return paired;
  }


  ///
  @override
  Future<String> getAdapterName() async {
    final String? name = await _bleAdHocManager.adapterName;
    return name == null ? '' : name;
  }


  ///
  @override
  Future<bool> updateDeviceName(String name) async {
    final bool? result = await _bleAdHocManager.updateDeviceName(name);
    return result == null ? false : result;
  }


  ///
  @override
  Future<bool> resetDeviceName() async {
    final bool? result = await _bleAdHocManager.resetDeviceName();
    return result == null ? false : result;
  }

/*------------------------------Private methods-------------------------------*/
  
  ///
  void _initialize() {
    if (_isInitialized)
      return;

    _isInitialized = true;
    // Listen to stream of ad hoc events
    _eventSub = _bleAdHocManager.eventStream.listen((AdHocEvent event) {
      // Notify upper layer of discovery event
      controller.add(event);

      switch (event.type) {
        case DEVICE_DISCOVERED:
          // Process potential peer discovered
          BleAdHocDevice device = event.payload as BleAdHocDevice;
          mapMacDevices.putIfAbsent(device.mac!, () {
            if (verbose) log(TAG, "Add " + device.mac! + " into mapMacDevices");
            return device;
          });
          break;

        case DISCOVERY_END:
          // Process end of discovery process
          if (verbose) log(TAG, 'Discovery end');
          (event.payload as Map).forEach((mac, device) {
            mapMacDevices.putIfAbsent(mac, () {
              if (verbose) log(TAG, "Add " + mac + " into mapMacDevices");
              return device;
            });
          });

          discoveryCompleted = true;
          _isDiscovering = false;
          _eventSub.pause();
          break;

        default:
      }
    });

    _eventSub.pause();
  }


  ///
  void _onEvent(Service service) {
    // Listen to stream of ad hoc events
    service.adhocEvent.listen((event) async { 
      switch (event.type) {
        case MESSAGE_RECEIVED:
          // Process message received
          _processMsgReceived(event.payload as MessageAdHoc);
          break;

        case CONNECTION_PERFORMED:
          // Process connection establishment
          List<dynamic> data = event.payload as List<dynamic>;
          String mac = data[0] as String;
          String uuid = data[1] as String;
          int service = data[2] as int;
          if (service == SERVER)
            break;

          // Store remote node's NetworkManager
          mapAddrNetwork.putIfAbsent(
            uuid, () => NetworkManager(
              (MessageAdHoc? msg) async => (service as ServiceClient).send(msg!), 
              () => (service as ServiceClient).disconnect()
            )
          );

          // Send message control containing MAC address of the remote node
          (service as ServiceClient).send(
            MessageAdHoc(
              Header(
                messageType: CONNECT_SERVER, 
                label: ownLabel,
                name: ownName,
                mac: ownMac,
                address: _ownBleUUID,
                deviceType: BLE
              ),
              mac
            )
          );
          break;

        case CONNECTION_ABORTED:
          // Process remote connection closed
          connectionClosed(event.payload as String?);
          break;

        case CONNECTION_EXCEPTION:
          // Notify upper layer of an exception occured at lower layer
          controller.add(AdHocEvent(INTERNAL_EXCEPTION, event.payload));
          break;

        default:
      }
    });
  }


  ///
  void _listenServer() {
    /// Start server listening 
    serviceServer = BleServer(verbose)..listen();
    /// Initialize the underlayer server service
    _bleAdHocManager.initialize();
    // Listen to the ad hoc events of the network (msg received, ...)
    _onEvent(serviceServer);
  }


  /// 
  Future<void> _connect(int attempts, final BleAdHocDevice bleAdHocDevice) async {
    final bleClient = BleClient(verbose, bleAdHocDevice, attempts, timeOut, _bleAdHocManager.eventStream);
    // Listen to the ad hoc events of the network (msg received, ...)
    _onEvent(bleClient);
    // Connect to the remote node
    await bleClient.connect();
  }


  ///
  void _processMsgReceived(final MessageAdHoc message) {
    switch (message.header.messageType) {
      case CONNECT_SERVER:
        // Recover this own node MAC and BLE address
        String? mac = message.header.mac;
        ownMac = message.pdu as String;
        _ownBleUUID = BLUETOOTHLE_UUID + ownMac.replaceAll(new RegExp(':'), '');
        _ownBleUUID = _ownBleUUID!.toLowerCase();

        // Notify upper layer of the recovery of this node's information
        controller.add(AdHocEvent(DEVICE_INFO_BLE, [ownMac, ownName]));

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
            mac
          ),
          mac!
        );

        // Process received message from remote nodes
        receivedPeerMessage(
          message.header,
          NetworkManager(
            (MessageAdHoc msg) async {
              msg.header.address = _ownBleUUID;
              msg.header.deviceType = BLE;
              await serviceServer.send(msg, mac);
            },
            () => serviceServer.cancelConnection(mac)
          )
        );
        break;

      case CONNECT_CLIENT:
        // Recover this own node MAC and BLE address
        ownMac = message.pdu as String;
        _ownBleUUID = BLUETOOTHLE_UUID + ownMac.replaceAll(new RegExp(':'), '').toLowerCase();

        // Notify upper layer of the recovery of this node's information
        controller.add(AdHocEvent(DEVICE_INFO_BLE, [ownMac, ownName]));

        // Process received message from remote nodes
        receivedPeerMessage(
          message.header, mapAddrNetwork[message.header.address]
        );
        break;

      case CONNECT_BROADCAST:
        FloodMsg floodMsg = FloodMsg.fromJson((message.pdu as Map) as Map<String, dynamic>);
        if (checkFloodEvent(floodMsg.id)) {
          // Rebroadcast the message to this node direct neighbors
          broadcastExcept(message, message.header.label);
          // Get message information
          HashSet<AdHocDevice?> hashSet = floodMsg.devices;
          for (AdHocDevice? device in hashSet) {
            if (device!.label != ownLabel && !setRemoteDevices.contains(device) 
              && !isDirectNeighbors(device.label)) {
              // Notify upper layer of a new remote connection established
              controller.add(AdHocEvent(CONNECTION_EVENT, device));

              setRemoteDevices.add(device);
            }
          }
        }
        break;

      case DISCONNECT_BROADCAST:
        if (checkFloodEvent(message.pdu as String?)) {
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
        // Notify upper layer of a message received
        controller.add(AdHocEvent(MESSAGE_EVENT, message));
    }
  }
}
