import 'dart:async';
import 'dart:collection';

import 'package:adhoclibrary/src/appframework/config.dart';
import 'package:adhoclibrary/src/datalink/ble/ble_adhoc_device.dart';
import 'package:adhoclibrary/src/datalink/ble/ble_adhoc_manager.dart';
import 'package:adhoclibrary/src/datalink/ble/ble_client.dart';
import 'package:adhoclibrary/src/datalink/ble/ble_constants.dart';
import 'package:adhoclibrary/src/datalink/ble/ble_server.dart';
import 'package:adhoclibrary/src/datalink/exceptions/device_failure.dart';
import 'package:adhoclibrary/src/datalink/service/adhoc_device.dart';
import 'package:adhoclibrary/src/datalink/service/connection_event.dart';
import 'package:adhoclibrary/src/datalink/service/discovery_event.dart';
import 'package:adhoclibrary/src/datalink/service/service.dart';
import 'package:adhoclibrary/src/datalink/utils/msg_adhoc.dart';
import 'package:adhoclibrary/src/datalink/utils/msg_header.dart';
import 'package:adhoclibrary/src/datalink/utils/utils.dart';
import 'package:adhoclibrary/src/network/datalinkmanager/abstract_wrapper.dart';
import 'package:adhoclibrary/src/network/datalinkmanager/flood_msg.dart';
import 'package:adhoclibrary/src/network/datalinkmanager/network_manager.dart';
import 'package:adhoclibrary/src/network/datalinkmanager/wrapper_conn_oriented.dart';
import 'package:adhoclibrary/src/network/datalinkmanager/adhoc_event.dart';


class WrapperBluetoothLE extends WrapperConnOriented {
  static const String TAG = "[WrapperBle]";

  bool _isDiscovering;
  BleAdHocManager _bleAdHocManager;
  StreamSubscription<DiscoveryEvent> _discoverySub;
  String _ownStringUUID;

  WrapperBluetoothLE(
    bool verbose, Config config, HashMap<String, AdHocDevice> mapMacDevices
  ) : super(verbose, config, mapMacDevices) {
    this._isDiscovering = false;
    this.type = Service.BLUETOOTHLE;
    this.init(verbose);
  }

/*------------------------------Override methods------------------------------*/

  @override
  Future<void> init(bool verbose, [Config config]) async {
    if (await BleAdHocManager.isEnabled()) {
      this._bleAdHocManager = BleAdHocManager(verbose);
      this.ownName = await BleAdHocManager.getCurrentName();
      this.ownMac = '';
      this._listenServer();
      this._initialize();
      this.enabled = true;
    } else {
      this.enabled = false;
    }
  }

  @override
  void enable(int duration, void Function(bool) onEnable) async {
    if (!enabled) {
      this._bleAdHocManager = BleAdHocManager(verbose);
      await _bleAdHocManager.enable();
      this._bleAdHocManager.enableDiscovery(duration);
      this._bleAdHocManager.onEnableBluetooth(onEnable);
      this.ownName = await BleAdHocManager.getCurrentName();
      this.ownMac = '';
      this._listenServer();
      this._initialize();
      this.enabled = true;
    } else {
      this._bleAdHocManager.enableDiscovery(duration);
    }
  }

  @override
  void disable() {
    mapAddrNetwork.clear();
    neighbors.clear();

    _bleAdHocManager.disable();
    _bleAdHocManager = null;

    enabled = false;
  }

  @override
  void discovery() {
    if (_isDiscovering)
      return;

    _discoverySub.resume();
    _bleAdHocManager.discovery();
    _isDiscovering = true;
  }

  @override
  void connect(int attempts, AdHocDevice adHocDevice) {
    BleAdHocDevice bleAdHocDevice = mapMacDevices[adHocDevice.mac];
    if (bleAdHocDevice != null) {
      if (!serviceServer.containConnection(bleAdHocDevice.mac)) {
        _connect(attempts, bleAdHocDevice);
      } else {
        throw DeviceFailureException(
          adHocDevice.name + "(" + adHocDevice.mac + ") is already connected"
        );
      }
    }
  }

  @override
  void stopListening() => serviceServer.stopListening();

  @override
  Future<HashMap<String, AdHocDevice>> getPaired() async {
    if (!(await BleAdHocManager.isEnabled()))
      return null;

    Map pairedDevices = await _bleAdHocManager.getPairedDevices();
    pairedDevices.forEach((macAddress, bleAdHocDevice) {
      mapMacDevices.putIfAbsent(macAddress, () => bleAdHocDevice);
    });

    return mapMacDevices;
  }

  @override
  Future<String> getAdapterName() async {
    return await _bleAdHocManager.adapterName;
  }

  @override
  Future<bool> updateDeviceName(String name) async {
    return await _bleAdHocManager.updateDeviceName(name);
  }

  @override
  Future<bool> resetDeviceName() async {
    return await _bleAdHocManager.resetDeviceName();
  }

/*------------------------------Private methods-------------------------------*/

  void _initialize() {
    _discoverySub = _bleAdHocManager.discoveryStream.listen((DiscoveryEvent event) {
      discoveryCtrl.add(event);

      switch (event.type) {
        case Service.DEVICE_DISCOVERED:
          BleAdHocDevice device = event.payload as BleAdHocDevice;
          mapMacDevices.putIfAbsent(device.mac, () {
            if (verbose) log(TAG, "Add " + device.mac + " into mapMacDevices");
            return device;
          });
          break;

        case Service.DISCOVERY_END:
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
    service.connStatusStream.listen((ConnectionEvent info) {
      switch (info.status) {
        case Service.CONNECTION_CLOSED:
          connectionClosed(info.address);
          break;

        case Service.CONNECTION_EXCEPTION:
          eventCtrl.add(AdHocEvent(AbstractWrapper.INTERNAL_EXCEPTION, info.error));
          break;

        default:
          break;
      }
    });

    service.messageStream.listen((MessageAdHoc msg) => _processMsgReceived(msg));
  }

  void _listenServer() {
    serviceServer = BleServer(verbose)..start();
    _onEvent(serviceServer);
  }

  void _connect(int attempts, final BleAdHocDevice bleAdHocDevice) {
    final bleClient = BleClient(verbose, bleAdHocDevice, attempts, timeOut);

    bleClient.connectListener = (String mac, String uuid) async {
      mapAddrNetwork.putIfAbsent(
        uuid, () => NetworkManager(
          (MessageAdHoc msg) => bleClient.send(msg), 
          () => bleClient.disconnect()
        )
      );

      await bleClient.send(MessageAdHoc(
        Header(
          messageType: AbstractWrapper.CONNECT_SERVER, 
          label: label,
          name: ownName,
          mac: ownMac,
          address: _ownStringUUID,
          deviceType: Service.BLUETOOTHLE
        ),
        mac
      ));
    };

    _onEvent(bleClient);
    bleClient.connect();
  }

  void _processMsgReceived(final MessageAdHoc message) {
    print(message.toString());
    switch (message.header.messageType) {
      case AbstractWrapper.CONNECT_SERVER:
        String mac = message.header.mac;
        ownMac = message.pdu as String;
        _ownStringUUID = BLUETOOTHLE_UUID + ownMac.replaceAll(new RegExp(':'), '');
        _ownStringUUID = _ownStringUUID.toLowerCase();

        eventCtrl.add(AdHocEvent(AbstractWrapper.DEVICE_INFO, ownMac, extra: ownName));

        serviceServer.send(
          MessageAdHoc(
            Header(
              messageType: AbstractWrapper.CONNECT_CLIENT, 
              label: label,
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
          message.header,
          NetworkManager(
            (MessageAdHoc msg) async => await serviceServer.send(msg, mac),
            () => serviceServer.cancelConnection(mac)
          )
        );
        break;

      case AbstractWrapper.CONNECT_CLIENT:
        ownMac = message.pdu as String;
        _ownStringUUID = BLUETOOTHLE_UUID + ownMac.replaceAll(new RegExp(':'), '').toLowerCase();

        eventCtrl.add(AdHocEvent(AbstractWrapper.DEVICE_INFO, ownMac, extra: ownName));

        receivedPeerMessage(
          message.header, mapAddrNetwork[message.header.address]
        );
        break;

      case AbstractWrapper.CONNECT_BROADCAST:
        FloodMsg floodMsg = FloodMsg.fromJson(message.pdu as Map);
        if (checkFloodEvent(floodMsg.id)) {
          broadcastExcept(message, message.header.label);

          HashSet<AdHocDevice> hashSet = floodMsg.adHocDevices;
          for (AdHocDevice adHocDevice in hashSet) {
            if (adHocDevice.label != label 
              && !setRemoteDevices.contains(adHocDevice)
              && !isDirectNeighbors(adHocDevice.label)
            ) {
              adHocDevice.directedConnected = false;

              eventCtrl.add(AdHocEvent(AbstractWrapper.CONNECTION_EVENT, adHocDevice));

              setRemoteDevices.add(adHocDevice);
            }
          }
        }
        break;

      case AbstractWrapper.DISCONNECT_BROADCAST:
        if (checkFloodEvent(message.pdu as String)) {
          broadcastExcept(message, message.header.label);

          Header header = message.header;
          AdHocDevice adHocDevice = AdHocDevice(
            label: header.label,
            name: header.name,
            mac: header.mac,
            type: type, 
            directedConnected: false
          );

          eventCtrl.add(AdHocEvent(AbstractWrapper.DISCONNECTION_EVENT, adHocDevice));

          if (setRemoteDevices.contains(adHocDevice))
            setRemoteDevices.remove(adHocDevice);
        }
        break;

      case AbstractWrapper.BROADCAST:
        Header header = message.header;

        eventCtrl.add(
          AdHocEvent(
            AbstractWrapper.DATA_RECEIVED, 
            AdHocDevice(
              label: header.label,
              name: header.name,
              mac: header.mac,
              type: header.deviceType
            ),
            extra: message.pdu
          )
        );
        break;

      default:
        eventCtrl.add(AdHocEvent(AbstractWrapper.MESSAGE_EVENT, message));
        break;
    }
  }
}
