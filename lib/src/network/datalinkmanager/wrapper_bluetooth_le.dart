import 'dart:collection';

import 'package:adhoclibrary/src/appframework/config.dart';
import 'package:adhoclibrary/src/datalink/ble/ble_adhoc_device.dart';
import 'package:adhoclibrary/src/datalink/ble/ble_adhoc_manager.dart';
import 'package:adhoclibrary/src/datalink/ble/ble_client.dart';
import 'package:adhoclibrary/src/datalink/ble/ble_server.dart';
import 'package:adhoclibrary/src/datalink/ble/ble_utils.dart';
import 'package:adhoclibrary/src/datalink/exceptions/device_failure.dart';
import 'package:adhoclibrary/src/datalink/service/adhoc_device.dart';
import 'package:adhoclibrary/src/datalink/service/discovery_listener.dart';
import 'package:adhoclibrary/src/datalink/service/service.dart';
import 'package:adhoclibrary/src/network/datalinkmanager/wrapper_conn_oriented.dart';


class WrapperBluetoothLE extends WrapperConnOriented {
  BleAdHocManager _bleAdHocManager;

  WrapperBluetoothLE(bool verbose, Config config,
                     HashMap<String, AdHocDevice> mapAddressDevice)
    : super(verbose, config, mapAddressDevice) {

    this.type = Service.BLUETOOTHLE;
    this._init(verbose);
  }

/*------------------------------Override methods------------------------------*/

  @override
  void connect(int attempts, AdHocDevice adHocDevice) {
    BleAdHocDevice bleAdHocDevice = 
      mapMacDevices[adHocDevice.macAddress] as BleAdHocDevice;
    if (bleAdHocDevice != null) {
      if (bleAdHocDevice == null) { // TODO: verify that device is not already connected in the conditional
        _connect(attempts, bleAdHocDevice);
      } else {
        throw DeviceFailureException(adHocDevice.deviceName
                + "(" + adHocDevice.macAddress + ") is already connected");
      }
    }
  }

  @override
  void stopListening() {
    serviceServer.stopListening();
  }

  @override
  void discovery(DiscoveryListener discoveryListener) {
    DiscoveryListener listener = DiscoveryListener(
      onDeviceDiscovered: (AdHocDevice device) {
        mapMacDevices.putIfAbsent(device.macAddress, () => device);
      },

      onDiscoveryCompleted: (HashMap<String, AdHocDevice> mapNameDevice) {
        if (_bleAdHocManager == null) {
          String errorMessage = 'Discovery process failure due to bluetooth connectivity';
          discoveryListener.onDiscoveryFailed(DeviceFailureException(errorMessage));
        } else {
          mapNameDevice.forEach((key, value) {
            mapMacDevices.putIfAbsent(key, () => value);
          });

          discoveryCompleted = true;
        }
      },

      onDiscoveryStarted: () {
        discoveryListener.onDiscoveryStarted();
      },
  
      onDiscoveryFailed: (Exception e) {
        discoveryListener.onDiscoveryFailed(e);
      }
    );

    _bleAdHocManager.startScan(listener);
  }

  @override
  Future<HashMap<String, AdHocDevice>> getPaired() async {
    if (!(await BleUtils.isEnabled()))
      return null;
    return null;
  }

  @override
  void unregisterConnection() {
      // Not used in bluetooth context
  }

  @override
  Future<bool> resetDeviceName() async {
    return await _bleAdHocManager.resetDeviceName();
  }

  @override
  Future<bool> updateDeviceName(String name) async {
    return await _bleAdHocManager.updateDeviceName(name);
  }

  @override
  Future<String> getAdapterName() async {
    return await _bleAdHocManager.adapterName;
  }

/*------------------------------Private methods-------------------------------*/

  void _init(bool verbose) async {
    if (await BleUtils.isEnabled()) {
      this._bleAdHocManager = BleAdHocManager(verbose);
      this.ownName = await BleUtils.getCurrentName();
      this._listenServer();
    }
  }

  void _connect(int attempts, final BleAdHocDevice bleAdHocDevice) {
    final BleClient bleClient = BleClient(bleAdHocDevice, attempts, timeOut);
    bleClient.connect();
  }

  void _listenServer() {
    serviceServer = BleServer()
      ..listen();
  }
}
