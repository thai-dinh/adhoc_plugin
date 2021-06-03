import 'dart:convert';

import 'package:adhoc_plugin/src/datalink/service/constants.dart';
import 'package:adhoc_plugin/src/datalink/utils/msg_adhoc.dart';
import 'package:flutter/services.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';


/// Class allowing to have access to platform-specific services. 
/// 
/// This class allows to perform a set of supported Ble operations.
class BleServices {
  static const String _methodName = 'ad.hoc.lib/ble.method.channel';
  static const String _eventName = 'ad.hoc.lib/ble.event.channel';
  static const MethodChannel _methodChannel = MethodChannel(_methodName);
  static const EventChannel _eventChannel = EventChannel(_eventName);
  static final Stream<Map<dynamic, dynamic>> _platformEventStream = _eventChannel
    .receiveBroadcastStream()
      .cast<Map<dynamic, dynamic>>()
      .asBroadcastStream();

  static int id = 0;

  const BleServices();

/*-----------------------------Getters & Setters-----------------------------*/

  /// Event stream of the platform-specific side.
  static Stream<Map<dynamic, dynamic>> get platformEventStream {
    return _platformEventStream;
  }

  /// Bluetooth adapter name.
  static Future<String> get bleAdapterName async {
    final name = await _methodChannel.invokeMethod('getAdapterName');
    return name == null ? '' : name as String;
  }

  /// Gets the list of already paired devices.
  /// 
  /// Returns a list of [Map] representing the information of the paired devices.
  static Future<List<Map<dynamic, dynamic>>> get pairedDevices async {
    return await _methodChannel.invokeMethod('getPairedDevices') 
      as List<Map<dynamic, dynamic>>;
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
    return await _methodChannel.invokeMethod('isEnabled') as bool;
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
    return await _methodChannel.invokeMethod('updateDeviceName', name) as bool;
  }


  /// Resets the local adapter name of the device.
  /// 
  /// Returns true if the name is successfully reset, otherwise false.
  static Future<bool> resetDeviceName() async {
    return await _methodChannel.invokeMethod('resetDeviceName') as bool;
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
  static Future<void> GATTSendMessage(MessageAdHoc message, String mac) async {
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
    return await _methodChannel.invokeMethod('getCurrentName') as String;
  }


  /// Gets the state of bond with the remote Ble-capable device of MAC addresss
  /// [mac].
  /// 
  /// Returns true if this device is bonded to the remote device, otherwise 
  /// false.
  static Future<bool> getBondState(String mac) async {
    return await _methodChannel.invokeMethod('getBondState', mac) as bool;
  }


  /// Initiates a pairing request with the remote Ble-capable device of MAC 
  /// addresss [mac].
  /// 
  /// Returns true if this device has been successfully bonded with the remote 
  /// device, otherwise false.
  static Future<bool> createBond(String mac) async {
    return await _methodChannel.invokeMethod('createBond', mac) as bool;
  }

  /// Writes data to the ad hoc characteristic.
  ///
  /// The [message] is transformed into bytes, which are then written to the
  /// characteristic of the remote host GATT server.
  /// 
  /// The remote host is identified by [mac].
  /// 
  /// The data is fragmented into smaller chunk of [mtu] bytes size.
  static Future<void> writeToCharacteristic(MessageAdHoc message, String mac, int mtu) async {
    var _reactiveBle = FlutterReactiveBle();
    var _characteristicUuid = Uuid.parse(CHARACTERISTIC_UUID);
    var _serviceUuid = Uuid.parse(SERVICE_UUID);

    // Get the characteristic of the remote host GATT server
    final characteristic = QualifiedCharacteristic(
      serviceId: _serviceUuid,
      characteristicId: _characteristicUuid,
      deviceId: mac
    );

    // Convert the MessageAdHoc into bytes
    var msg = Utf8Encoder().convert(json.encode(message.toJson()));
    int _id = id++ % UINT8_SIZE, _mtu = mtu - 3 - 2, i = 0, flag, end;

    /* Fragment the message bytes into smaller chunk of bytes */

    // First byte indicates the message ID and second byte the flag value
    // The flag value '0' determines the end of the fragmentation
    if (i + _mtu >= msg.length) {
      flag = MESSAGE_END;
      end = msg.length;
    } else {
      flag = MESSAGE_FRAG;
      end = i + _mtu;
    }

    do {
      var _chunk = [_id, flag] + List.from(msg.getRange(i, end));
      await _reactiveBle.writeCharacteristicWithoutResponse(
        characteristic, value: _chunk
      );

      flag = MESSAGE_FRAG;
      i += _mtu;

      if (i + _mtu >= msg.length) {
        flag = MESSAGE_END;
        end = msg.length;
      } else {
        end = i + _mtu;
      }
    } while (i < msg.length);
  }
}
