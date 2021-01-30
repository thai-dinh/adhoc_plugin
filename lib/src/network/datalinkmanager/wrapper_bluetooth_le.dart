import 'dart:collection';

import 'package:adhoclibrary/src/appframework/config.dart';
import 'package:adhoclibrary/src/datalink/ble/ble_adhoc_device.dart';
import 'package:adhoclibrary/src/datalink/ble/ble_adhoc_manager.dart';
import 'package:adhoclibrary/src/datalink/ble/ble_client.dart';
import 'package:adhoclibrary/src/datalink/ble/ble_server.dart';
import 'package:adhoclibrary/src/datalink/ble/ble_utils.dart';
import 'package:adhoclibrary/src/datalink/exceptions/device_already_connected.dart';
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
      if (bleAdHocDevice == null) {// TODO: verify that device is not already connected in the conditional
        _connect(attempts, bleAdHocDevice);
      } else {
        throw DeviceAlreadyConnectedException(adHocDevice.deviceName
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
    _bleAdHocManager.startScan();
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
