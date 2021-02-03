import 'dart:collection';

import 'package:adhoclibrary/src/appframework/config/config.dart';
import 'package:adhoclibrary/src/datalink/ble/ble_adhoc_device.dart';
import 'package:adhoclibrary/src/datalink/ble/ble_adhoc_manager.dart';
import 'package:adhoclibrary/src/datalink/ble/ble_client.dart';
import 'package:adhoclibrary/src/datalink/ble/ble_server.dart';
import 'package:adhoclibrary/src/datalink/ble/ble_utils.dart';
import 'package:adhoclibrary/src/datalink/exceptions/device_failure.dart';
import 'package:adhoclibrary/src/datalink/service/adhoc_device.dart';
import 'package:adhoclibrary/src/datalink/service/discovery_listener.dart';
import 'package:adhoclibrary/src/datalink/service/service.dart';
import 'package:adhoclibrary/src/datalink/service/service_msg_listener.dart';
import 'package:adhoclibrary/src/datalink/utils/msg_adhoc.dart';
import 'package:adhoclibrary/src/datalink/utils/msg_header.dart';
import 'package:adhoclibrary/src/datalink/utils/utils.dart';
import 'package:adhoclibrary/src/network/datalinkmanager/abstract_wrapper.dart';
import 'package:adhoclibrary/src/network/datalinkmanager/wrapper_conn_oriented.dart';


class WrapperBluetoothLE extends WrapperConnOriented {
  static const String TAG = "[FlutterAdHoc][WrapperBle]";

  BleAdHocManager _bleAdHocManager;

  WrapperBluetoothLE(
    bool verbose, Config config, HashMap<String, AdHocDevice> mapAddressDevice
  ) : super(verbose, config, mapAddressDevice) {
    this.type = Service.BLUETOOTHLE;
    this._init(verbose);
  }

/*------------------------------Override methods------------------------------*/

  @override
  void enable(int duration) {
    _bleAdHocManager = BleAdHocManager(v);
    _bleAdHocManager.enableDiscovery(duration);
    enabled = true;
  }

  @override
  void disable() {
    _bleAdHocManager.disable();
    _bleAdHocManager = null;
    enabled = false;
  }

  @override
  void discovery(DiscoveryListener discoveryListener) {
    DiscoveryListener listener = DiscoveryListener(
      onDeviceDiscovered: (AdHocDevice device) {
        mapMacDevices.putIfAbsent(device.macAddress, () => device);
        discoveryListener.onDeviceDiscovered(device);
      },

      onDiscoveryCompleted: (HashMap<String, AdHocDevice> mapNameDevice) {
        if (_bleAdHocManager == null) {
          String msg = 'Discovery process failed due to bluetooth connectivity';
          discoveryListener.onDiscoveryFailed(DeviceFailureException(msg));
        } else {
          print('Wrapper: Discovery completed');
          mapNameDevice.forEach((key, value) {
            mapMacDevices.putIfAbsent(key, () => value);
          });

          discoveryCompleted = true;

          discoveryListener.onDiscoveryCompleted(mapNameDevice);
        }
      },

      onDiscoveryStarted: () {
        discoveryListener.onDiscoveryStarted();
      },

      onDiscoveryFailed: (Exception exception) {
        discoveryListener.onDiscoveryFailed(exception);
      }
    );

    _bleAdHocManager.discovery(listener);
  }

  @override
  void connect(int attempts, AdHocDevice adHocDevice) {
    BleAdHocDevice bleAdHocDevice = mapMacDevices[adHocDevice.macAddress];
    if (bleAdHocDevice != null) {
      if (bleAdHocDevice != null) { // TODO: verify that device is not already connected in the conditional
        _connect(attempts, bleAdHocDevice);
      } else {
        throw DeviceFailureException(
          adHocDevice.deviceName + "(" + adHocDevice.macAddress + 
          ") is already connected"
        );
      }
    }
  }

  @override
  void stopListening() => serviceServer.stopListening();

  @override
  Future<HashMap<String, AdHocDevice>> getPaired() async {
    if (!(await BleUtils.isEnabled()))
      return null;

    Map pairedDevices = await _bleAdHocManager.getPairedDevices();
    pairedDevices.forEach((key, value) {
      mapMacDevices.putIfAbsent(key, () => value);
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

  void _init(bool verbose) async {
    if (await BleUtils.isEnabled()) {
      this._bleAdHocManager = BleAdHocManager(verbose);
      this.ownName = await BleUtils.getCurrentName();
      this.ownMac = '';
      this._listenServer();
    }
  }

  void _listenServer() {
    ServiceMessageListener listener = ServiceMessageListener(
      onMessageReceived: (MessageAdHoc message) {
        _processMsgReceived(message);
      },

      onConnectionClosed: (String remoteAddress) { },

      onConnection: (String remoteAddress) {
        if (v) Utils.log(TAG, 'onConnection: $remoteAddress');
      },
  
      onConnectionFailed: (Exception exception) { },

      onMsgException: (Exception exception) { }
    );

    serviceServer = BleServer(v, listener)..listen();
  }

  void _connect(int attempts, final BleAdHocDevice bleAdHocDevice) {
    ServiceMessageListener listener = ServiceMessageListener(
      onMessageReceived: (MessageAdHoc message) {
        _processMsgReceived(message);
      },

      onConnectionClosed: (String remoteAddress) { },

      onConnection: (String remoteAddress) { },
  
      onConnectionFailed: (Exception exception) { },

      onMsgException: (Exception exception) { }
    );

    final BleClient bleClient = BleClient(
      v, bleAdHocDevice, attempts, timeOut, listener
    );

    bleClient.connectListener = () {
      bleClient.send(MessageAdHoc(Header(
        messageType: AbstractWrapper.CONNECT_SERVER, 
        label: label, 
        name: ownName,
        address: ownMac
      )));
    };

    bleClient.connect();
  }

  void _processMsgReceived(final MessageAdHoc message) {
    switch (message.header.messageType) {
      case AbstractWrapper.CONNECT_SERVER:
        final String address = message.header.address;
        if (v) Utils.log(TAG, 'Service Server: CONNECT_SERVER: $address');
        // if (serviceServer.activeConnections.containsKey(address)) {
          serviceServer.send(
            MessageAdHoc(Header(
              messageType: AbstractWrapper.CONNECT_SERVER, 
              label: label, 
              name: ownName,
              address: ownMac
            )),
            address
          );
        // }
        break;

      case AbstractWrapper.CONNECT_CLIENT:
        if (v) Utils.log(TAG, 'Service Client: CONNECT_CLIENT');
        break;

      case AbstractWrapper.CONNECT_BROADCAST:
        break;

      case AbstractWrapper.DISCONNECT_BROADCAST:
        break;

      case AbstractWrapper.BROADCAST:
        break;
      
      default:
    }
  }
}
