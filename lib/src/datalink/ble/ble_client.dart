import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:adhoclibrary/src/datalink/ble/ble_adhoc_device.dart';
import 'package:adhoclibrary/src/datalink/ble/ble_utils.dart';
import 'package:adhoclibrary/src/datalink/exceptions/message_error.dart';
import 'package:adhoclibrary/src/datalink/exceptions/no_connection.dart';
import 'package:adhoclibrary/src/datalink/utils/msg_adhoc.dart';
import 'package:adhoclibrary/src/datalink/service/service.dart';
import 'package:adhoclibrary/src/datalink/service/service_client.dart';
import 'package:adhoclibrary/src/datalink/service/service_msg_listener.dart';
import 'package:adhoclibrary/src/datalink/utils/utils.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';


class BleClient extends ServiceClient {
  StreamSubscription<ConnectionStateUpdate> _connecStreamSub;
  StreamSubscription<List<int>> _msgStreamSub;
  FlutterReactiveBle _reactiveBle;
  Function _connectListener;
  BleAdHocDevice _device;

  Uuid serviceUuid;
  Uuid charMessageUuid;

  BleClient(
    bool verbose, this._device, int attempts, int timeOut, 
    ServiceMessageListener serviceMessageListener
  ) : super(
    verbose, Service.STATE_NONE, attempts, timeOut, serviceMessageListener
  ) {
    this._reactiveBle = FlutterReactiveBle();
    this.serviceUuid = Uuid.parse(BleUtils.ADHOC_SERVICE_UUID);
    this.charMessageUuid = Uuid.parse(BleUtils.ADHOC_CHARACTERISTIC_UUID);
  }

/*------------------------------Getters & Setters-----------------------------*/

  set connectListener(Function connectListener) {
    this._connectListener = connectListener;
  }

/*-------------------------------Public methods-------------------------------*/

  void connect() => _connect(attempts, Duration(milliseconds: backOffTime));

  void disconnect() {
    if (_connecStreamSub != null)
      _connecStreamSub.cancel();
  }

  void stopListening() {
    if (v) Utils.log(ServiceClient.TAG, 'stopListening()');

    if (_msgStreamSub != null)
      _msgStreamSub.cancel();
  }

  Future<void> send(MessageAdHoc message) async {
    if (v) Utils.log(ServiceClient.TAG, 'send()');

    if (state == Service.STATE_NONE)
      throw NoConnectionException('No remote connection');

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

/*------------------------------Private methods-------------------------------*/

  Future<void> _requestMtu() async {
    _device.mtu = await _reactiveBle.requestMtu(
      deviceId: _device.macAddress, 
      mtu: BleUtils.MAX_MTU
    );
  }

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
    if (v) Utils.log(ServiceClient.TAG, 'Connect to ${_device.macAddress}');

    if (state == Service.STATE_NONE || state == Service.STATE_CONNECTING) {
      _connecStreamSub = _reactiveBle.connectToDevice(
        id: _device.macAddress,
        servicesWithCharacteristicsToDiscover: {},
        connectionTimeout: Duration(seconds: timeOut),
      ).listen((event) async {
        switch (event.connectionState) {
          case DeviceConnectionState.connected:
            if (v)
              Utils.log(ServiceClient.TAG, 'Connected to ${_device.macAddress}');
            _requestMtu();
            if (_connectListener != null)
              _connectListener();

            _listen();
            state = Service.STATE_CONNECTED;
            break;
          case DeviceConnectionState.connecting:
            state = Service.STATE_CONNECTING;
            break;

          default:
            state = Service.STATE_NONE;
        }
      }, onError: (error) {
        throw NoConnectionException(
          error.toString() + ': Failed to connect to ${_device.macAddress}'
        );
      });
    }
  }

  Future<void> _writeValue(Uint8List values) async {
    final characteristic = QualifiedCharacteristic(
      serviceId: serviceUuid,
      characteristicId: charMessageUuid,
      deviceId: _device.macAddress
    );

    await _reactiveBle.writeCharacteristicWithResponse(
      characteristic, value: values.toList()
    );
  }

  void _listen() {
    if (v) Utils.log(ServiceClient.TAG, 'listen()');

    final characteristic = QualifiedCharacteristic(
      serviceId: serviceUuid,
      characteristicId: charMessageUuid,
      deviceId: _device.macAddress
    );

    _msgStreamSub =
      _reactiveBle.subscribeToCharacteristic(characteristic).listen((rawData) {
      serviceMessageListener.onMessageReceived(_processMessage(rawData));
    }, onError: (dynamic error) {
      serviceMessageListener.onMsgException(
        MessageErrorException(error.toString())
      );
    });
  }

  MessageAdHoc _processMessage(final List<int> rawMessage) {
    Uint8List _unprocessedMessage = Uint8List.fromList(rawMessage);
    String stringMessage = Utf8Decoder().convert(_unprocessedMessage);
    return MessageAdHoc.fromJson(json.decode(stringMessage));
  }
}
