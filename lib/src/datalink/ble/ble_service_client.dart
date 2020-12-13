import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:adhoclibrary/src/datalink/ble/ble_adhoc_device.dart';
import 'package:adhoclibrary/src/datalink/ble/ble_platform_manager.dart';
import 'package:adhoclibrary/src/datalink/ble/ble_util.dart';
import 'package:adhoclibrary/src/datalink/exceptions/no_connection.dart';
import 'package:adhoclibrary/src/datalink/message/msg_adhoc.dart';
import 'package:adhoclibrary/src/datalink/service/service.dart';
import 'package:adhoclibrary/src/datalink/service/service_client.dart';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BleServiceClient extends ServiceClient {
  StreamSubscription<ConnectionStateUpdate> _connectionLink;
  FlutterReactiveBle _client;
  BleAdHocDevice _device;
  BlePlatformManager _platformManager;
  List<Uint8List> _rawData;
  List<MessageAdHoc> _messages;

  Uuid serviceUuid;
  Uuid characteristicUuid;

  BleServiceClient(this._client, this._device, int attempts, int timeOut) 
    : super(Service.STATE_NONE, attempts, timeOut) {

    this._platformManager = BlePlatformManager();
    this._rawData = List.empty(growable: true);
    this._messages = List.empty(growable: true);
    this.serviceUuid = Uuid.parse(ADHOC_SERVICE_UUID);
    this.characteristicUuid = Uuid.parse(ADHOC_CHARACTERISTIC_UUID);
  }

  void listen() {
    _platformManager.messageStream(_device.macAddress).listen((event) {
      _rawData.add(event);
      if (event[0] == MESSAGE_END) {
        _processMessage();
      }
    });
  }

  void _processMessage() {
    Utf8Decoder decoder = Utf8Decoder();
    Uint8List rawMessage = _rawData.removeAt(0), buffer;

    do {
      buffer = _rawData.removeAt(0);
      rawMessage += buffer;
    } while (buffer[0] != MESSAGE_END);

    String stringMessage = decoder.convert(rawMessage);
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
    print("[AdHocPlugin] " + _device.macAddress);

    List<Uint8List> data = List.empty(growable: true);
    Utf8Encoder encoder = Utf8Encoder();
    Uint8List msg = encoder.convert(message.toString()), tmp;
    int mtu = _device.mtu-1, length = msg.length, start = 0, end = mtu;
    int index = MESSAGE_BEGIN;

    while (length > mtu) {
      tmp = msg.sublist(start, end);
      tmp.insert(0, index % UINT8_SIZE);
      index++;

      data.add(tmp);

      start += mtu;
      end += mtu;
      length -= mtu;
    }

    tmp = msg.sublist(start, start += length);
    tmp.insert(0, MESSAGE_END);
    data.add(tmp);

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
