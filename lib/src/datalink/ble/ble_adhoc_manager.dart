import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:adhoclibrary/src/appframework/listener_adapter.dart';
import 'package:adhoclibrary/src/datalink/ble/ble_adhoc_device.dart';
import 'package:adhoclibrary/src/datalink/ble/ble_utils.dart';
import 'package:adhoclibrary/src/datalink/exceptions/bad_duration.dart';
import 'package:adhoclibrary/src/datalink/exceptions/discovery_failed.dart';
import 'package:adhoclibrary/src/datalink/service/discovery_listener.dart';
import 'package:adhoclibrary/src/datalink/utils/msg_adhoc.dart';
import 'package:adhoclibrary/src/datalink/utils/utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';


class BleAdHocManager {
  static const String TAG = "[Ble.Manager]";
  static const String _channelName = 'ad.hoc.lib/plugin.ble.channel';
  static const MethodChannel _channel = const MethodChannel(_channelName);

  bool _verbose;
  bool _isDiscovering;
  DiscoveryListener _discoveryListener;
  FlutterReactiveBle _reactiveBle;
  HashMap<String, BleAdHocDevice> _hashMapBleDevice;
  StreamSubscription<DiscoveredDevice> _subscription;

  BleAdHocManager(this._verbose) {
    this._isDiscovering = false;
    this._reactiveBle = FlutterReactiveBle();
    this._hashMapBleDevice = HashMap<String, BleAdHocDevice>();
  }

/*------------------------------Getters & Setters-----------------------------*/

  Future<String> get adapterName => _channel.invokeMethod('getAdapterName');

  HashMap<String, BleAdHocDevice> get hashMapBleDevice => _hashMapBleDevice;

/*-------------------------------Public methods-------------------------------*/

  void enable() => _channel.invokeMethod('enable');

  void disable() => _channel.invokeMethod('disable');

  void enableDiscovery(int duration) {
    if (_verbose) Utils.log(TAG, 'enableDiscovery()');

    if (duration < 0 || duration > 3600) 
      throw BadDurationException(
        'Duration must be between 0 and 3600 second(s)'
      );

    _channel.invokeMethod('startAdvertise');
    Timer(Duration(seconds: duration), _stopAdvertise);
  }

  void discovery(DiscoveryListener discoveryListener) {
    if (_verbose) Utils.log(TAG, 'discovery()');

    if (_isDiscovering)
      this._stopScan();

    this._discoveryListener = discoveryListener;

    _hashMapBleDevice.clear();
    discoveryListener.onDiscoveryStarted();

    _subscription = _reactiveBle.scanForDevices(
      withServices: [Uuid.parse(BleUtils.ADHOC_SERVICE_UUID)],
      scanMode: ScanMode.lowLatency,
    ).listen((device) {
      BleAdHocDevice btDevice = BleAdHocDevice(device);

      if (!_hashMapBleDevice.containsKey(device.id)) {
        if (_verbose) {
          Utils.log(TAG, 'Device found: ' +
            'Name: ${device.name} - Address: ${device.id}'
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

  Future<bool> updateDeviceName(String name) async
    => await _channel.invokeMethod('updateDeviceName', name);

  Future<bool> resetDeviceName() async
    => await _channel.invokeMethod('resetDeviceName');

  void onEnableBluetooth(ListenerAdapter listenerAdapter) {
    _reactiveBle.statusStream.listen((status) {
      if (status == BleStatus.ready) {
        listenerAdapter.onEnableBluetooth(true);
      } else {
        listenerAdapter.onEnableBluetooth(false);
      } // TODO: other cases than ready ? -> unknown, unauthorized, locationServicesDisabled
    });
  }

/*------------------------------Private methods-------------------------------*/

  void _stopAdvertise() => _channel.invokeMethod('stopAdvertise');

  void _stopScan() {
    if (_verbose) Utils.log(TAG, 'Discovery process completed');

    _subscription.cancel();
    _subscription = null;
    _discoveryListener.onDiscoveryCompleted(_hashMapBleDevice);
  }

/*-------------------------------Static methods-------------------------------*/

  static void setVerbose(bool verbose)
    => _channel.invokeMethod('setVerbose', verbose);

  static Future<bool> isEnabled() async {
    return await _channel.invokeMethod('isEnabled');
  }

  static void openGattServer() => _channel.invokeMethod('openGattServer');

  static void closeGattServer() => _channel.invokeMethod('closeGattServer');

  static void serverSendMessage(MessageAdHoc message, String address) {
    _channel.invokeMethod('serverSendMessage', <String, String>{
      'address': address,
      'message': json.encode(message.toJson()),
    });
  }

  static Future<String> getCurrentName() async {
    return await _channel.invokeMethod('getCurrentName');
  }
}
