import 'dart:convert';

import 'package:adhoc_plugin/src/datalink/utils/msg_adhoc.dart';
import 'package:flutter/services.dart';


/// Class allowing to have access to platform-specific services. 
/// 
/// This class allows to perform a set of supported Ble operations.
class BleServices {
  static const String _methodName = 'ad.hoc.lib/ble.method.channel';
  static const String _eventName = 'ad.hoc.lib/ble.event.channel';
  static const MethodChannel _methodChannel = const MethodChannel(_methodName);
  static const EventChannel _eventChannel = const EventChannel(_eventName);
  static Stream<Map<dynamic, dynamic>> _platformEventStream = _eventChannel
    .receiveBroadcastStream()
      .cast<Map<dynamic, dynamic>>()
      .asBroadcastStream();

  const BleServices();

/*-----------------------------Getters & Setters-----------------------------*/

  /// Returns the stream of the platform-specific side.
  static Stream<Map<dynamic, dynamic>> get platformEventStream {
    return _platformEventStream;
  }


  /// Returns the Bluetooth adapter name.
  static Future<String> get bleAdapterName async {
    final String? name = await _methodChannel.invokeMethod('getAdapterName');
    return name == null ? '' : name;
  }


  /// Gets the list of already paired devices.
  /// 
  /// Returns a list of [Map] representing the information of the paired devices.
  static Future<List<Map>> get pairedDevices async {
    return await _methodChannel.invokeMethod('getPairedDevices');
  }


  /// Sets the verbose/debug mode if [verbose] is true.
  static set verbose(bool verbose) {
    _methodChannel.invokeMethod('setVerbose', verbose);
  }

/*------------------------------Adapter methods------------------------------*/

  /// Enables the Bluetooth adapter.
  static Future<void> enableBleAdapter() async {
    return await _methodChannel.invokeMethod('enable');
  }


  /// Disables the Bluetooth adapter.
  static Future<void> disableBleAdapter() async {
    return await _methodChannel.invokeMethod('disable');
  }


  /// Checks whether the Bluetooth adpater is enabled.
  /// 
  /// Returns true if it is, otherwise false.
  static Future<bool> isBleAdapterEnabled() async {
    return await _methodChannel.invokeMethod('isEnabled');
  }


  /// Starts the advertisement process.
  static void startAdvertise() {
    _methodChannel.invokeMethod('startAdvertise');
  }


  /// Stops the advertisement process.
  static void stopAdvertise() {
    _methodChannel.invokeMethod('stopAdvertise');
  }


  /// Updates the local adapter name of the device with [name].
  /// 
  /// Returns true if the name is successfully set, otherwise false.
  static Future<bool> updateDeviceName(String name) async {
    return await _methodChannel.invokeMethod('updateDeviceName', name);
  }


  /// Resets the local adapter name of the device.
  /// 
  /// Returns true if the name is successfully reset, otherwise false.
  static Future<bool> resetDeviceName() async {
    return await _methodChannel.invokeMethod('resetDeviceName');
  }

/*----------------------------Gatt Server methods----------------------------*/

  /// Opens the GATT server on the platform-specific side.
  static void openGATTServer() {
    _methodChannel.invokeMethod('openGattServer');
  }


  /// Closes the GATT server on the platform-specific side.
  static void closeGATTServer() {
    _methodChannel.invokeMethod('closeGattServer');
  }


  /// Gets the GATT server of the platform-specific side to send [message] to 
  /// the remote Ble-capable device of MAC addresss [mac].
  /// 
  /// Returns true if it has been successfully sent, otherwise false. 
  static Future<bool> GATTSendMessage(MessageAdHoc message, String mac) async {
    return await _methodChannel.invokeMethod('sendMessage', <String, String>{
      'mac': mac,
      'message': json.encode(message.toJson()),
    });
  }


  /// Cancels a connection to the remote Ble-capable device of MAC addresss 
  /// [mac].
  static Future<void> cancelConnection(String mac) async {
    return await _methodChannel.invokeMethod('cancelConnection', mac);
  }


  /// Gets the current name of the Bluetooth adapter.
  /// 
  /// Returns the name of the Bluetooth adapter as a String.
  static Future<String> getCurrentName() async {
    return await _methodChannel.invokeMethod('getCurrentName');
  }


  /// Gets the state of bond with the remote Ble-capable device of MAC addresss
  /// [mac].
  /// 
  /// Returns true if this device is bonded to the remote device, otherwise 
  /// false.
  static Future<bool> getBondState(String mac) async {
    return await _methodChannel.invokeMethod('getBondState', mac);
  }


  /// Initiates a pairing request with the remote Ble-capable device of MAC 
  /// addresss [mac].
  /// 
  /// Returns true if this device has been successfully bonded with the remote 
  /// device, otherwise false.
  static Future<bool> createBond(String mac) async {
    return await _methodChannel.invokeMethod('createBond', mac);
  }
}
