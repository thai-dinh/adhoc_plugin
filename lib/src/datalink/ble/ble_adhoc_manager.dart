import 'dart:async';
import 'dart:collection';

import 'package:adhoclibrary/src/datalink/ble/ble_adhoc_device.dart';
import 'package:adhoclibrary/src/datalink/ble/ble_utils.dart';
import 'package:adhoclibrary/src/datalink/exceptions/bad_duration.dart';
import 'package:adhoclibrary/src/datalink/exceptions/discovery_failed.dart';
import 'package:adhoclibrary/src/datalink/service/discovery_listener.dart';
import 'package:adhoclibrary/src/datalink/utils/utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';


class BleAdHocManager {
  static const String TAG = "[FlutterAdHoc][Ble.Manager]";
  static const String _channelName = 'ad.hoc.lib/plugin.ble.channel';
  static const MethodChannel _channel = const MethodChannel(_channelName);

  bool _verbose;
  bool _isDiscovering;
  DiscoveryListener _discoveryListener;
  FlutterReactiveBle _bleClient;
  HashMap<String, BleAdHocDevice> _hashMapBleDevice;
  StreamSubscription<DiscoveredDevice> _subscription;

  Uuid serviceUuid;
  Uuid characteristicUuid;

  BleAdHocManager(bool verbose) {
    this._verbose = verbose;
    this._isDiscovering = false;
    this._bleClient = FlutterReactiveBle();
    this._hashMapBleDevice = HashMap<String, BleAdHocDevice>();
    this.serviceUuid = Uuid.parse(BleUtils.ADHOC_SERVICE_UUID);
    this.characteristicUuid = Uuid.parse(BleUtils.ADHOC_CHAR_MESSAGE_UUID);
  }

/*------------------------------Getters & Setters-----------------------------*/

  Future<String> get adapterName => _channel.invokeMethod('getAdapterName');

  HashMap<String, BleAdHocDevice> get hashMapBleDevice => _hashMapBleDevice;

/*-------------------------------Public methods-------------------------------*/

  void disable() => _channel.invokeMethod('disable');

  void enable() => _channel.invokeMethod('enable');

  void enableDiscovery(int duration) {
    if (_verbose) Utils.log(TAG, 'enableDiscovery()');

    if (duration < 0 || duration > 3600) 
      throw BadDurationException(
        'Duration must be between 0 and 3600 second(s)'
      );

    _channel.invokeMethod('startAdvertise');
    Timer(Duration(milliseconds: duration), _stopAdvertise);
  }

  void discovery(DiscoveryListener discoveryListener) {
    if (_verbose) Utils.log(TAG, 'discovery()');

    if (_isDiscovering)
      this._stopScan();

    this._discoveryListener = discoveryListener;

    _hashMapBleDevice.clear();
    discoveryListener.onDiscoveryStarted();

    _subscription = _bleClient.scanForDevices(
      withServices: [serviceUuid],
      scanMode: ScanMode.lowLatency,
    ).listen((device) {
      BleAdHocDevice btDevice = BleAdHocDevice(device);

      if (!_hashMapBleDevice.containsKey(device.id)) {
        if (_verbose) {
          Utils.log(TAG, 'Device found ->' +
            'DeviceName: ${device.name} - DeviceHardwareAddress: ${device.id}'
          );
        }

        discoveryListener.onDeviceDiscovered(btDevice);
      }

      _hashMapBleDevice.putIfAbsent(device.id, () => btDevice);
    }, onError: (error) {
      _discoveryListener.onDiscoveryFailed(DiscoveryFailedException(
        'Discovery process failed: ' + error.toString()
      ));
    });

    Timer(Duration(milliseconds: Utils.DISCOVERY_TIME), _stopScan);
  }

  Future<HashMap<String, BleAdHocDevice>> getPairedDevices() async {
    if (_verbose) Utils.log(TAG, 'getPairedDevices()');

    HashMap<String, BleAdHocDevice> pairedDevices = HashMap();
    List<Map> btDevices = await _channel.invokeMethod('resetDeviceName');

    for (final device in btDevices) {
      pairedDevices.putIfAbsent(
        device['macAddress'], () => BleAdHocDevice.fromMap(device)
      );
    }

    return pairedDevices;
  }

  Future<bool> updateDeviceName(String name)
    => _channel.invokeMethod('updateDeviceName', name);

  Future<bool> resetDeviceName() => _channel.invokeMethod('resetDeviceName');

/*------------------------------Private methods-------------------------------*/

  void _stopAdvertise() => _channel.invokeMethod('stopAdvertise');

  void _stopScan() {
    if (_subscription != null) {
      _subscription.cancel();
      _subscription = null;
      _discoveryListener.onDiscoveryCompleted(_hashMapBleDevice);
    }
  }


/*-------------------------------Static methods-------------------------------*/

  static void updateVerbose(bool verbose)
    => _channel.invokeMethod('updateVerbose', verbose);

  static void openGattServer() => _channel.invokeMethod('openGattServer');

  static void closeGattServer() => _channel.invokeMethod('closeGattServer');
}
