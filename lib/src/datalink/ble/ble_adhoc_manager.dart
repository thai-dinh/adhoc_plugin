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


/// Class managing the Bluetooth Low Energy discovery and pairing process with
/// other BLE-capable devices.
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
  StreamController<DiscoveryEvent> _discoveryCtrl;
  StreamController<dynamic> _bondCtrl;
  StreamSubscription<DiscoveredDevice> _discoverySub;
  StreamSubscription<BleStatus> _statusSub;

  /// Initialize a newly created BleAdHocManager with the operation being logged
  /// in the console if [_verbose] is true
  BleAdHocManager(this._verbose) {
    this._isDiscovering = false;
    this._reactiveBle = FlutterReactiveBle();
    this._mapMacDevice = HashMap();
    this._discoveryCtrl = StreamController<DiscoveryEvent>();
    this._bondCtrl = StreamController<dynamic>.broadcast();
  }

/*------------------------------Getters & Setters-----------------------------*/

  Future<String> get adapterName => _methodChannel.invokeMethod('getAdapterName');

  Stream<DiscoveryEvent> get discoveryStream => _discoveryCtrl.stream;

  Stream<dynamic> get bondStream => _bondCtrl.stream;

/*-------------------------------Public methods-------------------------------*/

  void initialize() {
    _eventChannel.receiveBroadcastStream().listen((event) => _bondCtrl.add(event));
  }

  Future<bool> enable() async => await _methodChannel.invokeMethod('enable');

  Future<bool> disable() async {
    if (_statusSub != null)
      await _statusSub.cancel();
    return await _methodChannel.invokeMethod('disable');
  }

  /// Set the device into a discovery mode for [duration] seconds. This function
  /// throws an [BadDurationException] if the given duration exceeds 3600 seconds
  void enableDiscovery(int duration) {
    if (_verbose) log(TAG, 'enableDiscovery()');

    if (duration < 0 || duration > 3600) 
      throw BadDurationException('Duration must be between 0 and 3600 second(s)');

    _methodChannel.invokeMethod('startAdvertise');
    Timer(Duration(seconds: duration), () => _methodChannel.invokeMethod('stopAdvertise'));
  }

  /// Trigger the discovery of other BLE-capable devices process.
  void discovery() async  {
    if (_verbose) log(TAG, 'discovery()');

    if (_isDiscovering)
      _stopScan();

    _mapMacDevice.clear();

    _discoverySub = _reactiveBle.scanForDevices(
      withServices: [Uuid.parse(SERVICE_UUID)],
      scanMode: ScanMode.balanced,
    ).listen(
      (device) {
        BleAdHocDevice bleDevice = BleAdHocDevice(device);
        _mapMacDevice.putIfAbsent(bleDevice.mac, () {
          if (_verbose)
            log(TAG, 'Device found: Name: ${device.name} - Address: ${device.id}');

          _discoveryCtrl.add(DiscoveryEvent(DEVICE_DISCOVERED, bleDevice));
          return bleDevice;
        });
      },
    );

    _isDiscovering = true;
    _discoveryCtrl.add(DiscoveryEvent(DISCOVERY_START, null));

    Timer(Duration(milliseconds: DISCOVERY_TIME), () => _stopScan());
  }

  /// Return all the paired BLE-capable devices.
  Future<HashMap<String, BleAdHocDevice>> getPairedDevices() async {
    if (_verbose) log(TAG, 'getPairedDevices()');

    HashMap<String, BleAdHocDevice> pairedDevices = HashMap();
    List<Map> btDevices = await _methodChannel.invokeMethod('getPairedDevices');

    for (final device in btDevices)
      pairedDevices.putIfAbsent(device['macAddress'], () => BleAdHocDevice.fromMap(device));

    return pairedDevices;
  }

  /// Update the local adapter name of the device with [name] and return true
  /// if the name was successfully set, otherwise false.
  Future<bool> updateDeviceName(String name) async => await _methodChannel.invokeMethod('updateDeviceName', name);

  /// Reset the local adapter name of the device
  Future<bool> resetDeviceName() async => await _methodChannel.invokeMethod('resetDeviceName');

  void onEnableBluetooth() { // TODO
    _statusSub = _reactiveBle.statusStream.listen((status) async {
      switch (status) {
        case BleStatus.ready:

          break;

        default:
          break;
      }
    });
  }

/*------------------------------Private methods-------------------------------*/

  void _stopScan() {
    if (_verbose) log(TAG, 'Discovery end');

    _discoverySub.cancel();
    _discoverySub = null;

    _isDiscovering = false;

    _discoveryCtrl.add(DiscoveryEvent(DISCOVERY_END, _mapMacDevice));
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
