import 'dart:collection';

import 'package:adhoclibrary/src/appframework/config.dart';
import 'package:adhoclibrary/src/appframework/listener_adapter.dart';
import 'package:adhoclibrary/src/appframework/listener_app.dart';
import 'package:adhoclibrary/src/datalink/ble/ble_adhoc_device.dart';
import 'package:adhoclibrary/src/datalink/ble/ble_adhoc_manager.dart';
import 'package:adhoclibrary/src/datalink/ble/ble_client.dart';
import 'package:adhoclibrary/src/datalink/ble/ble_server.dart';
import 'package:adhoclibrary/src/datalink/exceptions/device_failure.dart';
import 'package:adhoclibrary/src/datalink/service/adhoc_device.dart';
import 'package:adhoclibrary/src/datalink/service/discovery_listener.dart';
import 'package:adhoclibrary/src/datalink/service/service.dart';
import 'package:adhoclibrary/src/datalink/service/service_client.dart';
import 'package:adhoclibrary/src/datalink/service/service_msg_listener.dart';
import 'package:adhoclibrary/src/datalink/utils/msg_adhoc.dart';
import 'package:adhoclibrary/src/datalink/utils/msg_header.dart';
import 'package:adhoclibrary/src/network/datalinkmanager/abstract_wrapper.dart';
import 'package:adhoclibrary/src/network/datalinkmanager/flood_msg.dart';
import 'package:adhoclibrary/src/network/datalinkmanager/wrapper_conn_oriented.dart';


class WrapperBluetoothLE extends WrapperConnOriented {
  static const String TAG = "[FlutterAdHoc][WrapperBle]";

  BleAdHocManager _bleAdHocManager;

  WrapperBluetoothLE(
    bool verbose, Config config, HashMap<String, AdHocDevice> mapAddressDevice,
    ListenerApp listenerApp
  ) : super(verbose, config, mapAddressDevice, listenerApp) {
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
    }
  }

  @override
  void enable(int duration, ListenerAdapter listenerAdapter) {
    _bleAdHocManager = BleAdHocManager(v);
    _bleAdHocManager.enable();
    _bleAdHocManager.enableDiscovery(duration);
    _bleAdHocManager.onEnableBluetooth(listenerAdapter);
    enabled = true;
  }

  @override
  void disable() {
    neighbors.neighbors.clear();

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
      if (!serviceServer.activeConnections.contains(bleAdHocDevice.macAddress)) {
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
    if (!(await BleAdHocManager.isEnabled()))
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

  void _listenServer() {
    ServiceMessageListener listener = ServiceMessageListener(
      onMessageReceived: (MessageAdHoc message) {
        _processMsgReceived(message);
      },

      onConnectionClosed: (String remoteAddress) {
        connectionClosed(remoteAddress);
      },

      onConnection: (String remoteAddress) { },
  
      onConnectionFailed: (Exception exception) {
        listenerApp.onConnectionFailed(exception);
      },

      onMsgException: (Exception exception) {
        listenerApp.processMsgException(exception);
      }
    );

    serviceServer = BleServer(v, listener)..listen();
  }

  void _connect(int attempts, final BleAdHocDevice bleAdHocDevice) {
    ServiceMessageListener listener = ServiceMessageListener(
      onMessageReceived: (MessageAdHoc message) {
        _processMsgReceived(message);
      },

      onConnectionClosed: (String remoteAddress) {
        connectionClosed(remoteAddress);
      },

      onConnection: (String remoteAddress) { },
  
      onConnectionFailed: (Exception exception) {
        listenerApp.onConnectionFailed(exception);
      },

      onMsgException: (Exception exception) {
        listenerApp.processMsgException(exception);
      }
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
        if (serviceServer.activeConnections.contains(address)) {
          serviceServer.send(
            MessageAdHoc(Header(
              messageType: AbstractWrapper.CONNECT_SERVER, 
              label: label, 
              name: ownName,
              address: ownMac
            )),
            address
          );
        }
        break;

      case AbstractWrapper.CONNECT_CLIENT:
        ServiceClient serviceClient = mapAddrClient[message.header.address];
        if (serviceClient != null)
          receivedPeerMessage(message.header, serviceClient);
        break;

      case AbstractWrapper.CONNECT_BROADCAST:
        if (checkFloodEvent((message.pdu as FloodMsg).id)) {
          broadcastExcept(message, message.header.label);

          HashSet<AdHocDevice> hashSet = (message.pdu as FloodMsg).adHocDevices;
          for (AdHocDevice adHocDevice in hashSet) {
            if (adHocDevice.label == label 
              && !setRemoteDevices.contains(adHocDevice)
              && !isDirectNeighbors(adHocDevice.label)
            ) {
              adHocDevice.directedConnected = false;

              listenerApp.onConnection(adHocDevice);

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
            deviceName: header.name,
            label: header.label,
            type: type, 
            directedConnected: false
          );

          listenerApp.onConnectionClosed(adHocDevice);

          if (setRemoteDevices.contains(adHocDevice))
              setRemoteDevices.remove(adHocDevice);
        }
        break;

      case AbstractWrapper.BROADCAST:
        Header header = message.header;

        listenerApp.onReceivedData(
          AdHocDevice(
            deviceName: header.name,
            label: header.label,
            macAddress: header.macAddress,
            type: type
          ),
          message.pdu
        );
        break;
      
      default:
    }
  }
}
