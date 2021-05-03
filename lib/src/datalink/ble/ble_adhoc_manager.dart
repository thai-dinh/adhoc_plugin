import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:adhoc_plugin/src/datalink/ble/ble_adhoc_device.dart';
import 'package:adhoc_plugin/src/datalink/exceptions/bad_duration.dart';
import 'package:adhoc_plugin/src/datalink/service/constants.dart';
import 'package:adhoc_plugin/src/datalink/service/discovery_event.dart';
import 'package:adhoc_plugin/src/datalink/utils/msg_adhoc.dart';
import 'package:adhoc_plugin/src/datalink/utils/utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';


class BleAdHocManager {
  static const String TAG = "[BleAdHocManager]";
  static const String _methodName = 'ad.hoc.lib/plugin.ble.channel';
  static const String _eventName = 'ad.hoc.lib/ble.bond';
  static const MethodChannel _methodChannel = const MethodChannel(_methodName);
  static const EventChannel _eventChannel = const EventChannel(_eventName);

  bool _verbose;
  bool _isDiscovering;
  FlutterReactiveBle _reactiveBle;
  HashMap<String, BleAdHocDevice> _mapMacDevice;
  StreamController<DiscoveryEvent> _controller;
  StreamController<dynamic> _eventController;
  StreamSubscription<DiscoveredDevice> _subscription;
  StreamSubscription<BleStatus> _stateStreamSub;

  BleAdHocManager(this._verbose) {
    this._isDiscovering = false;
    this._reactiveBle = FlutterReactiveBle();
    this._mapMacDevice = HashMap<String, BleAdHocDevice>();
    this._controller = StreamController<DiscoveryEvent>();
    this._eventController = StreamController<dynamic>.broadcast();
  }

/*------------------------------Getters & Setters-----------------------------*/

  Future<String> get adapterName => _methodChannel.invokeMethod('getAdapterName');

  HashMap<String, BleAdHocDevice> get hashMapBleDevice => _mapMacDevice;

  Stream<DiscoveryEvent> get discoveryStream => _controller.stream;

  Stream<dynamic> get bondStream => _eventController.stream;

/*-------------------------------Public methods-------------------------------*/

  void initialize() {
    _eventChannel.receiveBroadcastStream().listen((event) => _eventController.add(event));
  }

  Future<bool> enable() async => await _methodChannel.invokeMethod('enable');

  Future<bool> disable() async {
    if (_stateStreamSub != null)
      await _stateStreamSub.cancel();
    return await _methodChannel.invokeMethod('disable');
  }

  void enableDiscovery(int duration) {
    if (_verbose) log(TAG, 'enableDiscovery()');

    if (duration < 0 || duration > 3600) 
      throw BadDurationException(
        'Duration must be between 0 and 3600 second(s)'
      );

    _methodChannel.invokeMethod('startAdvertise');
    Timer(Duration(seconds: duration), () {
      _methodChannel.invokeMethod('stopAdvertise');
    });
  }

  void discovery() async  {
    if (_verbose) log(TAG, 'discovery()');

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

          _controller.add(DiscoveryEvent(DEVICE_DISCOVERED, bleAdHocDevice));
          return bleAdHocDevice;
        });
      },
    );

    _isDiscovering = true;
    _controller.add(DiscoveryEvent(DISCOVERY_START, null));

    Timer(Duration(milliseconds: DISCOVERY_TIME), () => _stopScan());
  }

  Future<HashMap<String, BleAdHocDevice>> getPairedDevices() async {
    if (_verbose) log(TAG, 'getPairedDevices()');

    HashMap<String, BleAdHocDevice> pairedDevices = HashMap();
    List<Map> btDevices = await _methodChannel.invokeMethod('getPairedDevices');

    for (final device in btDevices) {
      pairedDevices.putIfAbsent(
        device['macAddress'], () => BleAdHocDevice.fromMap(device)
      );
    }

    return pairedDevices;
  }

  Future<bool> updateDeviceName(String name) async => await _methodChannel.invokeMethod('updateDeviceName', name);

  Future<bool> resetDeviceName() async => await _methodChannel.invokeMethod('resetDeviceName');

  void onEnableBluetooth(void Function(bool) onEnable) {
    _stateStreamSub = _reactiveBle.statusStream.listen((status) async {
      switch (status) {
        case BleStatus.ready:
          onEnable(true);
          break;

        default:
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

    _controller.add(DiscoveryEvent(DISCOVERY_END, _mapMacDevice));
  }

/*-------------------------------Static methods-------------------------------*/

  static void setVerbose(bool verbose) => _methodChannel.invokeMethod('setVerbose', verbose);

  static Future<bool> isEnabled() async => await _methodChannel.invokeMethod('isEnabled');

  static void openGattServer() => _methodChannel.invokeMethod('openGattServer');

  static void closeGattServer() => _methodChannel.invokeMethod('closeGattServer');

  static Future<bool> gattServerSendMessage(MessageAdHoc message, String mac) async {
    return await _methodChannel.invokeMethod('sendMessage', <String, String>{
      'mac': mac,
      'message': json.encode(message.toJson()),
    });
  }

  static Future<void> cancelConnection(String mac) async => await _methodChannel.invokeMethod('cancelConnection', mac);

  static Future<String> getCurrentName() async => await _methodChannel.invokeMethod('getCurrentName');

  static Future<bool> getBondState(String mac) async => await _methodChannel.invokeMethod('getBondState', mac);

  static Future<bool> createBond(String mac) async => await _methodChannel.invokeMethod('createBond', mac);
}
