import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:adhoclibrary/src/datalink/ble/ble_adhoc_device.dart';
import 'package:adhoclibrary/src/datalink/ble/ble_util.dart';
import 'package:adhoclibrary/src/datalink/exceptions/no_connection.dart';
import 'package:adhoclibrary/src/datalink/message/msg_adhoc.dart';
import 'package:adhoclibrary/src/datalink/service/service.dart';
import 'package:adhoclibrary/src/datalink/service/service_client.dart';

import 'package:flutter/services.dart';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BleServiceClient extends ServiceClient {
  static const String _channelName = 'ad.hoc.lib/ble.message';
  static const EventChannel _channel = const EventChannel(_channelName);

  StreamSubscription<ConnectionStateUpdate> _connectionLink;
  FlutterReactiveBle _client;
  BleAdHocDevice _device;
  List<Uint8List> _rawData;
  List<MessageAdHoc> _messages;

  Uuid serviceUuid;
  Uuid characteristicUuid;

  BleServiceClient(this._client, this._device, int attempts, int timeOut) 
    : super(Service.STATE_NONE, attempts, timeOut) {

    this._rawData = List.empty(growable: true);
    this._messages = List.empty(growable: true);
    this.serviceUuid = Uuid.parse(ADHOC_SERVICE_UUID);
    this.characteristicUuid = Uuid.parse(ADHOC_CHARACTERISTIC_UUID);
  }

  void listenMessageEvent() {
    _channel.receiveBroadcastStream().listen((event) {
      if (event['macAddress'] == _device.macAddress) {
        _rawData = List<Uint8List>.from(event['values'].whereType<Uint8List>());
        _processMessage();
      }
    });
  }

  void _processMessage() {
    Uint8List rawMessage = Uint8List.fromList(_rawData.expand((x) {
      List<int> tmp = new List<int>.from(x); 
      tmp.removeAt(0); 
      return tmp;
    }).toList());

    String stringMessage = Utf8Decoder().convert(rawMessage);
    print(stringMessage);
    Map mapMessage = jsonDecode(stringMessage);
    MessageAdHoc message = MessageAdHoc.fromMap(mapMessage);
    _messages.add(message);
  }

  void connect() => _connect(attempts, Duration(milliseconds: backOffTime));

  void _connect(int attempts, Duration delay) async {
    try {
      _connectionAttempt();
    } on NoConnectionException {
      if (attempts > 0) {
        await Future.delayed(delay);
        return _connect(attempts - 1, delay * 2);
      }

      rethrow;
    }
  }

  void _connectionAttempt() async {
    if (state == Service.STATE_NONE || state == Service.STATE_CONNECTING) {
      _connectionLink = _client.connectToDevice(
        id: _device.macAddress,
        servicesWithCharacteristicsToDiscover: {},
        connectionTimeout: Duration(seconds: timeOut),
      ).listen((event) {
        print('Connection state: ${event.connectionState}');
        switch (event.connectionState) {
          case DeviceConnectionState.connected:
            state = Service.STATE_CONNECTED;
            break;
          case DeviceConnectionState.connecting:
            state = Service.STATE_CONNECTING;
            break;

          default:
            state = Service.STATE_NONE;
        }
      }, onError: (error) {
        print(error.toString());
      });
    }
  }

  void cancelConnection() {
    if (_connectionLink != null)
      _connectionLink.cancel();
  }

  void sendMessage(MessageAdHoc message) async {
    List<int> fragmentInt;
    List<Uint8List> data = List.empty(growable: true);
    Uint8List msg = Utf8Encoder().convert(message.toJson().toString());
    Uint8List fragmentByte;
    int mtu = _device.mtu-1, length = msg.length, start = 0, end = mtu;
    int index = MESSAGE_BEGIN;

    while (length > mtu) {
      fragmentInt = [index % UINT8_SIZE] + msg.sublist(start, end).toList();
      fragmentByte = Uint8List.fromList(fragmentInt);
      index++;

      data.add(fragmentByte);

      start += mtu;
      end += mtu;
      length -= mtu;
    }

    fragmentInt = [MESSAGE_END] + msg.sublist(start, start += length).toList();
    fragmentByte = Uint8List.fromList(fragmentInt);
    data.add(fragmentByte);

    while (data.length > 0)
      await _writeValue(data.removeAt(0));
  }

  Future<void> _writeValue(Uint8List values) async {
    final characteristic = 
      QualifiedCharacteristic(serviceId: serviceUuid,
                              characteristicId: characteristicUuid,
                              deviceId: _device.macAddress);
    await _client.writeCharacteristicWithResponse(characteristic,
                                            value: values.toList());
  }

  MessageAdHoc receiveMessage() {
    MessageAdHoc message;

    if (_messages.length > 0) {
      message = _messages.removeAt(0);
    } else {
      message = null;
    }

    return message;
  }
}
