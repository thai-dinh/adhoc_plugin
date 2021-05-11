import 'dart:async';
import 'dart:collection';

import 'package:adhoc_plugin/src/appframework/config.dart';
import 'package:adhoc_plugin/src/datalink/ble/ble_adhoc_device.dart';
import 'package:adhoc_plugin/src/datalink/ble/ble_adhoc_manager.dart';
import 'package:adhoc_plugin/src/datalink/ble/ble_client.dart';
import 'package:adhoc_plugin/src/datalink/ble/ble_server.dart';
import 'package:adhoc_plugin/src/datalink/exceptions/device_failure.dart';
import 'package:adhoc_plugin/src/datalink/service/adhoc_device.dart';
import 'package:adhoc_plugin/src/datalink/service/adhoc_event.dart';
import 'package:adhoc_plugin/src/datalink/service/constants.dart';
import 'package:adhoc_plugin/src/datalink/service/discovery_event.dart';
import 'package:adhoc_plugin/src/datalink/service/service.dart';
import 'package:adhoc_plugin/src/datalink/service/service_client.dart';
import 'package:adhoc_plugin/src/datalink/utils/msg_adhoc.dart';
import 'package:adhoc_plugin/src/datalink/utils/msg_header.dart';
import 'package:adhoc_plugin/src/datalink/utils/utils.dart';
import 'package:adhoc_plugin/src/network/datalinkmanager/constants.dart';
import 'package:adhoc_plugin/src/network/datalinkmanager/flood_msg.dart';
import 'package:adhoc_plugin/src/network/datalinkmanager/network_manager.dart';
import 'package:adhoc_plugin/src/network/datalinkmanager/wrapper_network.dart';


class WrapperBle extends WrapperNetwork {
  static const String TAG = "[WrapperBle]";

  late bool _isDiscovering;
  late bool _isInitialized;
  BleAdHocManager? _bleAdHocManager;
  late StreamSubscription<DiscoveryEvent> _discoverySub;
  String? _ownStringUUID;

  WrapperBle(
    bool verbose, Config config, HashMap<String, AdHocDevice>? mapMacDevices
  ) : super(verbose, config, mapMacDevices) {
    this._isDiscovering = false;
    this._isInitialized = false;
    this.ownMac = '';
    this.type = BLE;
    this.init(verbose, null);
  }

/*------------------------------Override methods------------------------------*/

  @override
  Future<void> init(bool verbose, Config? config) async {
    if (await (BleAdHocManager.isEnabled() as Future<bool>)) {
      this._bleAdHocManager = BleAdHocManager(verbose);
      this.ownName = await BleAdHocManager.getCurrentName();
      this._listenServer();
      this._initialize();
      this.enabled = true;
    } else {
      this.enabled = false;
    }
  }

  @override
  void enable(int duration) async {
    if (!enabled!) {
      this._bleAdHocManager = BleAdHocManager(verbose);
      await _bleAdHocManager!.enable();
      this._bleAdHocManager!.enableDiscovery(duration);
      this.ownName = await BleAdHocManager.getCurrentName();
      this._listenServer();
      this._initialize();
      this.enabled = true;
    } else {
      this._bleAdHocManager!.enableDiscovery(duration);
    }
  }

  @override
  void disable() {
    mapAddrNetwork.clear();
    neighbors.clear();

    _bleAdHocManager!.disable();
    _bleAdHocManager = null;

    enabled = false;
  }

  @override
  void discovery() {
    if (_isDiscovering)
      return;

    _discoverySub.resume();
    _bleAdHocManager!.discovery();
    _isDiscovering = true;
  }

  @override
  Future<void> connect(int attempts, AdHocDevice device) async {
    BleAdHocDevice? bleAdHocDevice = mapMacDevices[device.mac] as BleAdHocDevice?;
    if (bleAdHocDevice != null) {
      if (!serviceServer!.containConnection(bleAdHocDevice.mac)) {
        await _connect(attempts, bleAdHocDevice);
      } else {
        throw DeviceFailureException(
          device.name! + "(" + device.mac! + ") is already connected"
        );
      }
    }
  }

  @override
  void stopListening() => serviceServer!.stopListening();

  @override
  Future<HashMap<String?, AdHocDevice>?> getPaired() async {
    if (!(await (BleAdHocManager.isEnabled() as Future<bool>)))
      return null;

    HashMap<String?, BleAdHocDevice> paired = HashMap();
    Map pairedDevices = await _bleAdHocManager!.getPairedDevices();
    pairedDevices.forEach((macAddress, bleAdHocDevice) {
      paired.putIfAbsent(macAddress, () => bleAdHocDevice);
    });

    return paired;
  }

  @override
  Future<String?> getAdapterName() async {
    return await _bleAdHocManager!.adapterName;
  }

  @override
  Future<bool?> updateDeviceName(String name) async {
    return await _bleAdHocManager!.updateDeviceName(name);
  }

  @override
  Future<bool?> resetDeviceName() async {
    return await _bleAdHocManager!.resetDeviceName();
  }

/*------------------------------Private methods-------------------------------*/

  void _initialize() {
    if (_isInitialized)
      return;

    _isInitialized = true;

    _discoverySub = _bleAdHocManager!.discoveryStream.listen((DiscoveryEvent event) {
      discoveryCtrl.add(event);

      switch (event.type) {
        case DEVICE_DISCOVERED:
          BleAdHocDevice device = event.payload as BleAdHocDevice;
          mapMacDevices.putIfAbsent(device.mac, () {
            if (verbose) log(TAG, "Add " + device.mac! + " into mapMacDevices");
            return device;
          });
          break;

        case DISCOVERY_END:
          if (verbose) log(TAG, 'Discovery end');
          (event.payload as Map).forEach((mac, device) {
            mapMacDevices.putIfAbsent(mac, () {
              if (verbose) log(TAG, "Add " + mac + " into mapMacDevices");
              return device;
            });
          });

          discoveryCompleted = true;
          _isDiscovering = false;
          _discoverySub.pause();
          break;

        default:
          break;
      }
    });

    _discoverySub.pause();
  }

  void _onEvent(Service service) {
    service.adhocEvent.listen((event) async { 
      switch (event.type) {
        case MESSAGE_RECEIVED:
          _processMsgReceived(event.payload as MessageAdHoc);
          break;

        case CONNECTION_PERFORMED:
          List<dynamic> data = event.payload as List<dynamic>;
          String mac = data[0];
          String uuid = data[1];
          if (data[2] == 0)
            break;

          mapAddrNetwork.putIfAbsent(
            uuid, () => NetworkManager(
              (MessageAdHoc? msg) async => (service as ServiceClient).send(msg!), 
              () => (service as ServiceClient).disconnect()
            )
          );

          (service as ServiceClient).send(
            MessageAdHoc(
              Header(
                messageType: CONNECT_SERVER, 
                label: ownLabel,
                name: ownName,
                mac: ownMac,
                address: _ownStringUUID,
                deviceType: BLE
              ),
              mac
            )
          );
          break;

        case CONNECTION_ABORTED:
          connectionClosed(event.payload as String?);
          break;

        case CONNECTION_EXCEPTION:
          eventCtrl.add(AdHocEvent(INTERNAL_EXCEPTION, event.payload));
          break;

        default:
      }
    });
  }

  void _listenServer() {
    serviceServer = BleServer(verbose)..listen();
    _bleAdHocManager!.initialize();
    _onEvent(serviceServer!);
  }

  Future<void> _connect(int attempts, final BleAdHocDevice bleAdHocDevice) async {
    final bleClient = BleClient(verbose, bleAdHocDevice, attempts, timeOut, _bleAdHocManager!.bondStream);
    _onEvent(bleClient);
    await bleClient.connect();
  }

  void _processMsgReceived(final MessageAdHoc message) {
    switch (message.header!.messageType) {
      case CONNECT_SERVER:
        String? mac = message.header!.mac;
        ownMac = message.pdu as String?;
        _ownStringUUID = BLUETOOTHLE_UUID + ownMac!.replaceAll(new RegExp(':'), '');
        _ownStringUUID = _ownStringUUID!.toLowerCase();

        eventCtrl.add(AdHocEvent(DEVICE_INFO_BLE, [ownMac, ownName]));

        serviceServer!.send(
          MessageAdHoc(
            Header(
              messageType: CONNECT_CLIENT, 
              label: ownLabel,
              name: ownName,
              mac: ownMac,
              address: _ownStringUUID,
              deviceType: type
            ),
            mac
          ),
          mac
        );

        receivedPeerMessage(
          message.header!,
          NetworkManager(
            (MessageAdHoc? msg) async => await serviceServer!.send(msg!, mac),
            () => serviceServer!.cancelConnection(mac)
          )
        );
        break;

      case CONNECT_CLIENT:
        ownMac = message.pdu as String?;
        _ownStringUUID = BLUETOOTHLE_UUID + ownMac!.replaceAll(new RegExp(':'), '').toLowerCase();

        eventCtrl.add(AdHocEvent(DEVICE_INFO_BLE, [ownMac, ownName]));

        receivedPeerMessage(
          message.header!, mapAddrNetwork[message.header!.address]
        );
        break;

      case CONNECT_BROADCAST:
        FloodMsg floodMsg = FloodMsg.fromJson((message.pdu as Map) as Map<String, dynamic>);
        if (checkFloodEvent(floodMsg.id)) {
          broadcastExcept(message, message.header!.label);

          HashSet<AdHocDevice> hashSet = floodMsg.adHocDevices!;
          for (AdHocDevice device in hashSet) {
            if (device.label != ownLabel 
              && !setRemoteDevices!.contains(device)
              && !isDirectNeighbors(device.label)
            ) {
              device.directedConnected = false;

              eventCtrl.add(AdHocEvent(CONNECTION_EVENT, device));

              setRemoteDevices!.add(device);
            }
          }
        }
        break;

      case DISCONNECT_BROADCAST:
        if (checkFloodEvent(message.pdu as String?)) {
          broadcastExcept(message, message.header!.label);

          Header header = message.header!;
          AdHocDevice adHocDevice = AdHocDevice(
            label: header.label,
            name: header.name,
            mac: header.mac,
            type: type, 
            directedConnected: false
          );

          eventCtrl.add(AdHocEvent(DISCONNECTION_EVENT, adHocDevice));

          if (setRemoteDevices!.contains(adHocDevice))
            setRemoteDevices!.remove(adHocDevice);
        }
        break;

      case BROADCAST:
        Header header = message.header!;
        AdHocDevice adHocDevice = AdHocDevice(
          label: header.label,
          name: header.name,
          mac: header.mac,
          type: header.deviceType
        );

        eventCtrl.add(AdHocEvent(DATA_RECEIVED, [adHocDevice, message.pdu]));
        break;

      default:
        eventCtrl.add(AdHocEvent(MESSAGE_EVENT, message));
        break;
    }
  }
}
