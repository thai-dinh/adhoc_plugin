import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:adhoc_plugin/src/datalink/ble/ble_adhoc_device.dart';
import 'package:adhoc_plugin/src/datalink/exceptions/bad_duration.dart';
import 'package:adhoc_plugin/src/datalink/service/adhoc_event.dart';
import 'package:adhoc_plugin/src/datalink/service/constants.dart';
import 'package:adhoc_plugin/src/datalink/service/service_manager.dart';
import 'package:adhoc_plugin/src/datalink/utils/msg_adhoc.dart';
import 'package:adhoc_plugin/src/datalink/utils/utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';


/// Class managing the Bluetooth Low Energy discovery and pairing process with
/// other remote Ble-capable devices.
class BleAdHocManager extends ServiceManager {
  static const String TAG = '[BleAdHocManager]';

  static const String _methodName = 'ad.hoc.lib/plugin.ble.channel';
  static const String _eventName = 'ad.hoc.lib/ble.bond';
  static const MethodChannel _methodChannel = const MethodChannel(_methodName);
  static const EventChannel _eventChannel = const EventChannel(_eventName);

  StreamSubscription<DiscoveredDevice>? _discoverySub;
  StreamSubscription<BleStatus>? _statusSub;

  late FlutterReactiveBle _reactiveBle;
  late HashMap<String?, BleAdHocDevice?> _mapMacDevice;

  /// Creates a [BleAdHocManager] object.
  /// 
  /// The debug/verbose mode is set if [verbose] is true.
  BleAdHocManager(bool verbose) : super(verbose) {
    this._reactiveBle = FlutterReactiveBle();
    this._mapMacDevice = HashMap();
  }

/*------------------------------Getters & Setters-----------------------------*/

  /// Returns the name of the Bluetooth adapter.
  /// 
  /// In case of error, a null value is returned.
  Future<String?> get adapterName => _methodChannel.invokeMethod('getAdapterName');

/*-------------------------------Public methods-------------------------------*/

  @override
  void close() {
    super.close();
    _reactiveBle.deinitialize();
    if (_discoverySub != null)
      _discoverySub!.cancel();
    if (_statusSub != null)
      _statusSub!.cancel();
  }

  /// Initializes the listening process of platform-side streams.
  void initialize() {
    _eventChannel.receiveBroadcastStream().listen(
      (event) => controller.add(event)
    );
  }

  /// Enables the Bluetooth adapter.
  Future<void> enable() async => await _methodChannel.invokeMethod('enable');

  /// Disables the Bluetooth adapter.
  Future<void> disable() async {
    if (_statusSub != null)
      await _statusSub!.cancel();
    await _methodChannel.invokeMethod('disable');
  }

  /// Sets this device into a discovery mode for [duration] seconds. 
  /// 
  /// Throws an [BadDurationException] if the given duration exceeds 3600 
  /// seconds.
  void enableDiscovery(int duration) {
    if (verbose) log(TAG, 'enableDiscovery()');

    if (duration < 0 || duration > 3600) {
      throw BadDurationException(
        'Duration must be between 0 and 3600 second(s)'
      );
    }

    _methodChannel.invokeMethod('startAdvertise');
  
    Timer(
      Duration(seconds: duration), 
      () => _methodChannel.invokeMethod('stopAdvertise')
    );
  }

  /// Triggers the discovery of other Ble-capable devices.
  void discovery()  {
    if (verbose) log(TAG, 'discovery()');

    // If a discovery process is ongoing, then cancel the process
    if (isDiscovering)
      _stopScan();

    // Clear the history of discovered devices
    _mapMacDevice.clear();

    // Start the discovery process
    _discoverySub = _reactiveBle.scanForDevices(
      withServices: [Uuid.parse(SERVICE_UUID)],
      scanMode: ScanMode.balanced,
    ).listen(
      (device) {
        // Get a BleAdHocDevice object from device
        BleAdHocDevice bleDevice = BleAdHocDevice(device);
        // Add the discovered device to the HashMap
        _mapMacDevice.putIfAbsent(bleDevice.mac, () {
          if (verbose) {
            log(
              TAG, 'Device found: Name: ${device.name} - Address: ${device.id}'
            );
          }

          // Notify upper layer of a device discovered
          controller.add(AdHocEvent(DEVICE_DISCOVERED, bleDevice));
          return bleDevice;
        });
      },
    );

    isDiscovering = true;
    // Notify upper layer of the discovery process' start
    controller.add(AdHocEvent(DISCOVERY_START, null));
    // Stop the discovery process after DISCOVERY_TIME
    Timer(Duration(milliseconds: DISCOVERY_TIME), () => _stopScan());
  }

  /// Returns all the paired Ble-capable devices.
  Future<HashMap<String?, BleAdHocDevice>> getPairedDevices() async {
    if (verbose) log(TAG, 'getPairedDevices()');

    HashMap<String?, BleAdHocDevice> pairedDevices = HashMap();
    // Request list of paired devices
    List<Map> btDevices = await _methodChannel.invokeMethod('getPairedDevices');

    for (final device in btDevices) {
      pairedDevices.putIfAbsent(
        device['macAddress'], () => BleAdHocDevice.fromMap(device)
      );
    }

    return pairedDevices;
  }

  /// Updates the local adapter name of the device with [name].
  /// 
  /// Returns true if the name is successfully set, otherwise false. In case
  /// of error, a null value is returned.
  Future<bool?> updateDeviceName(String name) async 
    => await _methodChannel.invokeMethod('updateDeviceName', name);

  /// Resets the local adapter name of the device.
  /// 
  /// Returns true if the name is successfully reset, otherwise false. In case
  /// of error, a null value is returned.
  Future<bool?> resetDeviceName() async 
    => await _methodChannel.invokeMethod('resetDeviceName');

  /// Listens to the status of the Bluetooth adapter.
  void onEnableBluetooth() {
    _statusSub = _reactiveBle.statusStream.listen((status) async {
      if (status == BleStatus.ready) {
        // Notify upper layer of Bluetooth being enabled and ready to be used
        controller.add(AdHocEvent(BLE_READY, true));
      }
    });
  }

/*------------------------------Private methods-------------------------------*/

  /// Stops the discovery process.
  void _stopScan() {
    if (verbose) log(TAG, 'Discovery end');

    // Unsubscribe to the discovery stream
    _discoverySub!.cancel();
    _discoverySub = null;

    isDiscovering = false;
    // Notify upper layer of the discovery process' end
    controller.add(AdHocEvent(DISCOVERY_END, _mapMacDevice));
  }

/*-------------------------------Static methods-------------------------------*/

  /// Sets the debug/verbose mode is set to [verbose] on the platform-specific 
  /// side.
  static void setVerbose(bool verbose) 
    => _methodChannel.invokeMethod('setVerbose', verbose);

  /// Checks whether the Bluetooth adapter is enabled or not.
  /// 
  /// In case of error, a null value is returned.
  static Future<bool?> isEnabled() async 
    => await _methodChannel.invokeMethod('isEnabled');

  /// Opens the GATT server on the platform-specific side.
  static void openGATTServer() => _methodChannel.invokeMethod('openGattServer');

  /// Closes the GATT server on the platform-specific side.
  static void closeGATTServer() => _methodChannel.invokeMethod('closeGattServer');

  /// Gets the GATT server of the platform-specific side to send [message] to 
  /// the remote Ble-capable device of MAC addresss [mac].
  /// 
  /// Returns true if it has been successfully sent, otherwise false. 
  /// 
  /// In case of error, a null value is returned.
  static Future<bool?> GATTSendMessage(MessageAdHoc message, String mac) async {
    return await _methodChannel.invokeMethod('sendMessage', <String, String>{
      'mac': mac,
      'message': json.encode(message.toJson()),
    });
  }

  /// Cancels a connection to the remote Ble-capable device of MAC addresss 
  /// [mac].
  static Future<void> cancelConnection(String mac) async 
    => await _methodChannel.invokeMethod('cancelConnection', mac);

  /// Gets the current name of the Bluetooth adapter.
  /// 
  /// Returns the name of the Bluetooth adapter as a String.
  /// 
  /// In case of error, a null value is returned.
  static Future<String?> getCurrentName() async 
    => await _methodChannel.invokeMethod('getCurrentName');

  /// Gets the state of bond with the remote Ble-capable device of MAC addresss
  /// [mac].
  /// 
  /// Returns true if this device is bonded to the remote device, otherwise 
  /// false.
  /// 
  /// In case of error, a null value is returned.
  static Future<bool?> getBondState(String mac) async 
    => await _methodChannel.invokeMethod('getBondState', mac);

  /// Initiates a pairing request with the remote Ble-capable device of MAC 
  /// addresss [mac].
  /// 
  /// Returns true if this device has been successfully bonded with the remote 
  /// device, otherwise false.
  /// 
  /// In case of error, a null value is returned.
  static Future<bool?> createBond(String mac) async 
    => await _methodChannel.invokeMethod('createBond', mac);
}
