import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:adhoclibrary/src/datalink/ble/ble_adhoc_device.dart';
import 'package:adhoclibrary/src/datalink/ble/ble_constants.dart';
import 'package:adhoclibrary/src/datalink/exceptions/bad_duration.dart';
import 'package:adhoclibrary/src/datalink/service/discovery_event.dart';
import 'package:adhoclibrary/src/datalink/service/service.dart';
import 'package:adhoclibrary/src/datalink/utils/msg_adhoc.dart';
import 'package:adhoclibrary/src/datalink/utils/utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:location/location.dart';


class BleAdHocManager {
  static const String TAG = "[BleAdHocManager]";
  static const String _channelName = 'ad.hoc.lib/plugin.ble.channel';
  static const MethodChannel _channel = const MethodChannel(_channelName);

  static bool isGranted = false;
  static bool isRequested = false;
  static bool isLocationOn = false;

  bool _verbose;
  bool _isDiscovering;
  Location _location;
  FlutterReactiveBle _reactiveBle;
  HashMap<String, BleAdHocDevice> _mapMacDevice;
  StreamController<DiscoveryEvent> _controller;
  StreamSubscription<DiscoveredDevice> _subscription;
  StreamSubscription<BleStatus> _stateStreamSub;

  BleAdHocManager(this._verbose) {
    this._isDiscovering = false;
    this._location = Location();
    this._reactiveBle = FlutterReactiveBle();
    this._mapMacDevice = HashMap<String, BleAdHocDevice>();
    this._controller = StreamController<DiscoveryEvent>();
  }

/*------------------------------Getters & Setters-----------------------------*/

  Future<String> get adapterName => _channel.invokeMethod('getAdapterName');

  HashMap<String, BleAdHocDevice> get hashMapBleDevice => _mapMacDevice;

  Stream<DiscoveryEvent> get discoveryStream => _controller.stream;

/*-------------------------------Public methods-------------------------------*/

  Future<bool> enable() async => await _channel.invokeMethod('enable');

  Future<bool> disable() async {
    if (_stateStreamSub != null)
      await _stateStreamSub.cancel();
    return await _channel.invokeMethod('disable');
  }

  void enableDiscovery(int duration) {
    if (_verbose) log(TAG, 'enableDiscovery()');

    if (duration < 0 || duration > 3600) 
      throw BadDurationException(
        'Duration must be between 0 and 3600 second(s)'
      );

    _channel.invokeMethod('startAdvertise');
    Timer(Duration(seconds: duration), () {
      _channel.invokeMethod('stopAdvertise');
    });
  }

  void discovery() async  {
    if (_verbose) log(TAG, 'discovery()');

    if (!isRequested && !isGranted) {
      await _requestPermission();
      if (!isGranted)
        return;
    } else if (isRequested && !isGranted) {
      return;
    }

    if (_isDiscovering)
      _stopScan();

    _mapMacDevice.clear();

    _subscription = _reactiveBle.scanForDevices(
      withServices: [Uuid.parse(SERVICE_UUID)],
      scanMode: ScanMode.lowLatency,
    ).listen(
      (device) {
        BleAdHocDevice bleAdHocDevice = BleAdHocDevice(device);
        _mapMacDevice.putIfAbsent(device.id, () {
          if (_verbose)
            log(TAG, 'Device found: Name: ${device.name} - Address: ${device.id}');

          _controller.add(DiscoveryEvent(Service.DEVICE_DISCOVERED, bleAdHocDevice));
          return bleAdHocDevice;
        });
      },
    );

    _isDiscovering = true;
    _controller.add(DiscoveryEvent(Service.DISCOVERY_STARTED, null));

    Timer(Duration(milliseconds: DISCOVERY_TIME), () => _stopScan());
  }

  Future<HashMap<String, BleAdHocDevice>> getPairedDevices() async {
    if (_verbose) log(TAG, 'getPairedDevices()');

    HashMap<String, BleAdHocDevice> pairedDevices = HashMap();
    List<Map> btDevices = await _channel.invokeMethod('resetDeviceName');

    for (final device in btDevices) {
      pairedDevices.putIfAbsent(
        device['macAddress'], () => BleAdHocDevice.fromMap(device)
      );
    }

    return pairedDevices;
  }

  Future<bool> updateDeviceName(String name) async => await _channel.invokeMethod('updateDeviceName', name);

  Future<bool> resetDeviceName() async => await _channel.invokeMethod('resetDeviceName');

  void onEnableBluetooth(void Function(bool) onEnable) {
    _stateStreamSub = _reactiveBle.statusStream.listen((status) async {
      switch (status) {
        case BleStatus.ready:
          onEnable(true);
          break;
        case BleStatus.unauthorized:
          if (!isRequested)
            await _requestPermission();
          break;
        case BleStatus.unknown:
          break;
        case BleStatus.unsupported:
          break;
        case BleStatus.poweredOff:
          break;
        case BleStatus.locationServicesDisabled:
          isLocationOn = await _location.serviceEnabled();
          if (!isLocationOn)
            isLocationOn = await _location.requestService();
          break;
      }
    });
  }

/*------------------------------Private methods-------------------------------*/

  void _stopScan() {
    if (_verbose) log(TAG, 'Discovery end');

    _subscription.cancel();
    _subscription = null;

    _isDiscovering = false;

    _controller.add(DiscoveryEvent(Service.DISCOVERY_END, _mapMacDevice));
  }

  Future<void> _requestPermission() async {
    PermissionStatus permissionGranted;

    permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted == PermissionStatus.granted)
        isGranted = true;
    } else if (permissionGranted == PermissionStatus.granted) {
      isGranted = true;
    }

    isRequested = true;
  }

/*-------------------------------Static methods-------------------------------*/

  static void setVerbose(bool verbose)
    => _channel.invokeMethod('setVerbose', verbose);

  static Future<bool> isEnabled() async {
    return await _channel.invokeMethod('isEnabled');
  }

  static void openGattServer() => _channel.invokeMethod('openGattServer');

  static void closeGattServer() => _channel.invokeMethod('closeGattServer');

  static Future<void> gattServerSendMessage(MessageAdHoc message, String mac) async {
    await _channel.invokeMethod('sendMessage', <String, String>{
      'mac': mac,
      'message': json.encode(message.toJson()),
    });
  }

  static Future<void> cancelConnection(String mac) async {
    await _channel.invokeMethod('cancelConnection', mac);
  }

  static Future<String> getCurrentName() async {
    return await _channel.invokeMethod('getCurrentName');
  }
}
