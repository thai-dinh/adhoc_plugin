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
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:uuid/uuid.dart' as DartUUID;


class BleClient extends ServiceClient {
  StreamSubscription<ConnectionStateUpdate> _connectionStreamSub;
  StreamSubscription<dynamic> _messageStreamSub;
  FlutterReactiveBle _reactiveBle;
  BleAdHocDevice _device;
  String _clientUID;

  Uuid serviceUuid;
  Uuid charMessageUuid;
  Uuid charConnUuid;

  BleClient(bool verbose, this._device, int attempts, int timeOut) 
    : super(verbose, Service.STATE_NONE, attempts, timeOut) {

    this._reactiveBle = FlutterReactiveBle();
    this._clientUID = DartUUID.Uuid().v1();

    this.serviceUuid = Uuid.parse(BleUtils.ADHOC_SERVICE_UUID);
    this.charMessageUuid = Uuid.parse(BleUtils.ADHOC_CHAR_MESSAGE_UUID);
    this.charConnUuid = Uuid.parse(BleUtils.ADHOC_CHAR_CONN_UUID);
  }

/*-------------------------------Public methods-------------------------------*/

  void connect() => _connect(attempts, Duration(milliseconds: backOffTime));

  void disconnect() {
    if (_connectionStreamSub != null)
      _connectionStreamSub.cancel();
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
    mtu = await _reactiveBle.requestMtu(deviceId: _device.macAddress, mtu: mtu);
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
    if (v) Utils.log(ServiceClient.TAG, 'Connect to ${_device.macAddress}');

    if (state == Service.STATE_NONE || state == Service.STATE_CONNECTING) {
      _connectionStreamSub = _reactiveBle.connectToDevice(
        id: _device.macAddress,
        servicesWithCharacteristicsToDiscover: {},
        connectionTimeout: Duration(seconds: timeOut),
      ).listen((event) async {
        switch (event.connectionState) {
          case DeviceConnectionState.connected:
            if (v)
              Utils.log(ServiceClient.TAG, 'Connected to ${_device.macAddress}');

            this._initListenProcess();
            this._listen();
            state = Service.STATE_CONNECTED;
            break;
          case DeviceConnectionState.connecting:
            state = Service.STATE_CONNECTING;
            break;

          default:
            state = Service.STATE_NONE;
            throw NoConnectionException(
              'Failed to connect to ${_device.macAddress}'
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
    final characteristic = QualifiedCharacteristic(
      serviceId: serviceUuid,
      characteristicId: charMessageUuid,
      deviceId: _device.macAddress
    );

    await _reactiveBle.writeCharacteristicWithResponse(
      characteristic, value: values.toList()
    );
  }

  void _initListenProcess() {
    Utf8Encoder encoder = Utf8Encoder();

    final characteristic = QualifiedCharacteristic(
      serviceId: serviceUuid,
      characteristicId: charConnUuid,
      deviceId: _device.macAddress
    );

    _reactiveBle.writeCharacteristicWithoutResponse(
      characteristic, value: encoder.convert(_clientUID).toList()
    );
  }

  void _listen() {
    if (v) Utils.log(ServiceClient.TAG, 'listen()');

    List<List<int>> rawData = List.empty(growable: true);

    final QualifiedCharacteristic characteristic = 
      QualifiedCharacteristic(serviceId: serviceUuid,
                              characteristicId: charMessageUuid,
                              deviceId: _device.macAddress);

    _reactiveBle.subscribeToCharacteristic(characteristic).listen((data) {
      rawData.add(data);
      if (data[0] == BleUtils.MESSAGE_END) {
        MessageAdHoc message = _processMessage(rawData);
        if (message.header.uuid == _clientUID) {
          rawData.clear();

          // TODO: process message received
        } 
      }
    }, onError: (dynamic error) {
      // TODO: handle error
    });
  }

  MessageAdHoc _processMessage(final List<List<int>> rawMessage) {
    Uint8List _unprocessedMessage = Uint8List.fromList(rawMessage.expand((x) {
      List<int> tmp = new List<int>.from(x); 
      tmp.removeAt(0);
      return tmp;
    }).toList());

    String stringMessage = Utf8Decoder().convert(_unprocessedMessage);
    return MessageAdHoc.fromJson(json.decode(stringMessage));
  }
}
