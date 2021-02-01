import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:adhoclibrary/src/datalink/ble/ble_adhoc_device.dart';
import 'package:adhoclibrary/src/datalink/ble/ble_utils.dart';
import 'package:adhoclibrary/src/datalink/exceptions/no_connection.dart';
import 'package:adhoclibrary/src/datalink/utils/msg_adhoc.dart';
import 'package:adhoclibrary/src/datalink/service/service.dart';
import 'package:adhoclibrary/src/datalink/service/service_client.dart';
import 'package:adhoclibrary/src/datalink/utils/utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';


class BleClient extends ServiceClient {
  static const String _channelName = 'ad.hoc.lib/ble.message';
  static const EventChannel _channel = const EventChannel(_channelName);

  StreamSubscription<ConnectionStateUpdate> _connectionStreamSub;
  StreamSubscription<dynamic> _messageStreamSub;
  FlutterReactiveBle _bleClient;
  BleAdHocDevice _device;
  List<MessageAdHoc> _messages;

  Uuid serviceUuid;
  Uuid characteristicUuid;

  BleClient(bool verbose, this._device, int attempts, int timeOut) 
    : super(verbose, Service.STATE_NONE, attempts, timeOut) {

    this._bleClient = FlutterReactiveBle();
    this._messages = List.empty(growable: true);
    this.serviceUuid = Uuid.parse(BleUtils.ADHOC_SERVICE_UUID);
    this.characteristicUuid = Uuid.parse(BleUtils.ADHOC_CHARACTERISTIC_UUID);
  }

/*-------------------------------Public methods-------------------------------*/

  void connect() => _connect(attempts, Duration(milliseconds: backOffTime));

  void disconnect() {
    if (_connectionStreamSub != null)
      _connectionStreamSub.cancel();
  }

  void listen() {
    if (v) Utils.log(ServiceClient.TAG, 'listen()');

    _messageStreamSub = _channel.receiveBroadcastStream().listen((event) {
      if (event['macAddress'] == _device.macAddress) {
        if (v) Utils.log(ServiceClient.TAG, 'Message received');

        List<Uint8List> _rawMessage = 
          List<Uint8List>.from(event['values'].whereType<Uint8List>());
        _processMessage(_rawMessage);
      }
    });
  }

  void stopListening() {
    if (v) Utils.log(ServiceClient.TAG, 'stopListening()');

    if (_messageStreamSub != null)
      _messageStreamSub.cancel();
  }

  void send(MessageAdHoc message) async {
    if (v) Utils.log(ServiceClient.TAG, 'send()');

    List<int> msgAsListInteger;
    List<Uint8List> msgAsListBytes = List.empty(growable: true);
    Uint8List msg = Utf8Encoder().convert(json.encode(message.toJson()));
    int mtu = _device.mtu-1, length = msg.length, start = 0, end = mtu;
    int index = BleUtils.MESSAGE_BEGIN;

    while (length > mtu) {
      msgAsListInteger = 
        [index % BleUtils.UINT8_SIZE] + msg.sublist(start, end).toList();
      msgAsListBytes.add(Uint8List.fromList(msgAsListInteger));

      index++;
      start += mtu;
      end += mtu;
      length -= mtu;
    }

    msgAsListInteger = 
      [BleUtils.MESSAGE_END] + msg.sublist(start, start + length).toList();
    msgAsListBytes.add(Uint8List.fromList(msgAsListInteger));

    while (msgAsListBytes.length > 0)
      await _writeValue(msgAsListBytes.removeAt(0));
  }

  void requestMtu(int mtu) async {  
    mtu = await _bleClient.requestMtu(deviceId: _device.macAddress, mtu: mtu);
    _device.mtu = mtu;
  }

/*------------------------------Private methods-------------------------------*/

  Future<void> _connect(int attempts, Duration delay) async {
    try {
      await _connectionAttempt();
    } on NoConnectionException {
      if (attempts > 0) {
        if (v)
          Utils.log(ServiceClient.TAG, 'Connection attempt $attempts failed');
        
        await Future.delayed(delay);
        return _connect(attempts - 1, delay * 2);
      }

      rethrow;
    }
  }

  Future<void> _connectionAttempt() async {
    if (v) {
      Utils.log(ServiceClient.TAG, 
        'Connect to ${_device.deviceName} (${_device.macAddress})'
      );
    }

    if (state == Service.STATE_NONE || state == Service.STATE_CONNECTING) {
      _connectionStreamSub = _bleClient.connectToDevice(
        id: _device.macAddress,
        servicesWithCharacteristicsToDiscover: {},
        connectionTimeout: Duration(seconds: timeOut),
      ).listen((event) {
        switch (event.connectionState) {
          case DeviceConnectionState.connected:
            state = Service.STATE_CONNECTED;
            if (v) {
              Utils.log(ServiceClient.TAG, 
                'Connected to ${_device.deviceName}' +
                ' (${_device.macAddress})'
              );
            }
            break;
          case DeviceConnectionState.connecting:
            state = Service.STATE_CONNECTING;
            break;

          default:
            state = Service.STATE_NONE;
            throw NoConnectionException(
              'Failed to connect to ${_device.deviceName} (${_device.macAddress})'
            );
        }
      }, onError: (error) {
        throw NoConnectionException(
          error.toString() + ': Unable to connect to ${_device.macAddress}'
        );
      });
    }
  }

  Future<void> _writeValue(Uint8List values) async {
    final characteristic = 
      QualifiedCharacteristic(serviceId: serviceUuid,
                              characteristicId: characteristicUuid,
                              deviceId: _device.macAddress);

    await _bleClient.writeCharacteristicWithResponse(
      characteristic, value: values.toList()
    );
  }

  void _processMessage(final List<Uint8List> rawMessage) {
    Uint8List _unprocessedMessage = Uint8List.fromList(rawMessage.expand((x) {
      List<int> tmp = new List<int>.from(x); 
      tmp.removeAt(0);
      return tmp;
    }).toList());

    String stringMessage = Utf8Decoder().convert(_unprocessedMessage);
    MessageAdHoc message = MessageAdHoc.fromJson(json.decode(stringMessage));
    _messages.add(message);
  }
}
