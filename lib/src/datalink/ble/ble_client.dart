import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:adhoclibrary/src/datalink/ble/ble_adhoc_device.dart';
import 'package:adhoclibrary/src/datalink/ble/ble_utils.dart';
import 'package:adhoclibrary/src/datalink/exceptions/no_connection.dart';
import 'package:adhoclibrary/src/datalink/service/discovery_event.dart';
import 'package:adhoclibrary/src/datalink/service/service.dart';
import 'package:adhoclibrary/src/datalink/service/service_client.dart';
import 'package:adhoclibrary/src/datalink/utils/msg_adhoc.dart';
import 'package:adhoclibrary/src/datalink/utils/utils.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';


class BleClient extends ServiceClient {
  StreamSubscription<ConnectionStateUpdate> _connecStreamSub;
  StreamSubscription<List<int>> _msgStreamSub;
  StreamSubscription<List<int>> _idStreamSub;
  FlutterReactiveBle _reactiveBle;
  BleAdHocDevice _device;
  Uuid _serviceUuid;
  Uuid _charMessageUuid;
  Uuid _identifierUuid;

  void Function(String) _connectListener;

  BleClient(
    bool verbose, this._device, int attempts, int timeOut,
    void Function(DiscoveryEvent) onEvent,
    void Function(dynamic) onError
  ) : super(
    verbose, Service.STATE_NONE, attempts, timeOut, onEvent, onError
  ) {
    this._reactiveBle = FlutterReactiveBle();
    this._serviceUuid = Uuid.parse(BleUtils.SERVICE_UUID);
    this._charMessageUuid = Uuid.parse(BleUtils.CHARACTERISTIC_UUID);
    this._identifierUuid = Uuid.parse(BleUtils.IDENTIFIER_UUID);
  }

/*------------------------------Getters & Setters-----------------------------*/

  set connectListener(void Function(String) connectListener) {
    this._connectListener = connectListener;
  }

/*-------------------------------Public methods-------------------------------*/

  void listen() {
    if (v) Utils.log(ServiceClient.TAG, 'Client: listen()');

    final msgCharacteristic = QualifiedCharacteristic(
      serviceId: _serviceUuid,
      characteristicId: _charMessageUuid,
      deviceId: _device.mac
    );

    _msgStreamSub = _reactiveBle.subscribeToCharacteristic(msgCharacteristic)
      .listen((List<int> rawData) {
        Uint8List messageAsListByte = Uint8List.fromList(rawData);
        String strMessage = Utf8Decoder().convert(messageAsListByte);
        MessageAdHoc message = MessageAdHoc.fromJson(json.decode(strMessage));
        onEvent(DiscoveryEvent(Service.MESSAGE_RECEIVED, message));
      },
      onError: onError
    );

    final idCharacteristic = QualifiedCharacteristic(
      serviceId: _serviceUuid,
      characteristicId: _identifierUuid,
      deviceId: _device.mac
    );

    _idStreamSub = _reactiveBle.subscribeToCharacteristic(idCharacteristic)
      .listen((List<int> rawData) {
        String ownMac = Utf8Decoder().convert(Uint8List.fromList(rawData));
        onEvent(DiscoveryEvent(Service.MAC_EXCHANGE_CLIENT, ownMac));

        _idStreamSub.cancel();
        _idStreamSub = null;
      },
      onError: onError
    );
  }

  void stopListening() {
    if (v) Utils.log(ServiceClient.TAG, 'Client: stopListening()');

    if (_msgStreamSub != null)
      _msgStreamSub.cancel();

    if (_idStreamSub != null)
      _idStreamSub.cancel();
  }

  void connect() => _connect(attempts, Duration(milliseconds: backOffTime));

  void disconnect() {
    if (_connecStreamSub != null)
      _connecStreamSub.cancel();

    onEvent(DiscoveryEvent(Service.CONNECTION_CLOSED, _device.mac));
  }

  Future<void> send(MessageAdHoc message) async {
    if (v) Utils.log(ServiceClient.TAG, 'Client: sendMessage()');

    if (state == Service.STATE_NONE)
      throw NoConnectionException('No remote connection');

    final characteristic = QualifiedCharacteristic(
      serviceId: _serviceUuid,
      characteristicId: _charMessageUuid,
      deviceId: _device.mac
    );

    await _send(json.encode(message.toJson()), characteristic);
  }

  Future<void> sendMacAddress(String mac) async {
    final characteristic = QualifiedCharacteristic(
      serviceId: _serviceUuid,
      characteristicId: _identifierUuid,
      deviceId: _device.mac
    );

    await _reactiveBle.writeCharacteristicWithResponse(
      characteristic, value: Utf8Encoder().convert(mac).toList()
    );
  }

/*------------------------------Private methods-------------------------------*/

  Future<void> _requestMtu() async {
    _device.mtu = await _reactiveBle.requestMtu(
      deviceId: _device.mac, 
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
    if (v) Utils.log(ServiceClient.TAG, 'Connect to ${_device.mac}');

    if (state == Service.STATE_NONE || state == Service.STATE_CONNECTING) {
      _connecStreamSub = _reactiveBle.connectToDevice(
        id: _device.mac,
        servicesWithCharacteristicsToDiscover: {},
        connectionTimeout: Duration(seconds: timeOut),
      ).listen((event) {
        switch (event.connectionState) {
          case DeviceConnectionState.connected:
            if (v)
              Utils.log(ServiceClient.TAG, 'Connected to ${_device.mac}');
            _requestMtu();

            onEvent(DiscoveryEvent(
              Service.CONNECTION_PERFORMED, _device.mac
            ));

            if (_connectListener != null)
              _connectListener(_device.mac);

            state = Service.STATE_CONNECTED;
            break;

          case DeviceConnectionState.connecting:
            state = Service.STATE_CONNECTING;
            break;

          default:
            state = Service.STATE_NONE;
        }
      }, onError: onError); 
    }
  }

  Future<void> _send(String data, QualifiedCharacteristic qChar) async {
    Uint8List msg = Utf8Encoder().convert(data), chunk;
    int mtu = _device.mtu-1, length = msg.length, start = 0, end = mtu;
    int index = BleUtils.MESSAGE_BEGIN;

    while (length > mtu) {
      chunk = msg.sublist(start, end);
      await _reactiveBle.writeCharacteristicWithResponse(
        qChar, value: [index % BleUtils.UINT8_SIZE] + chunk.toList()
      );

      index++;
      start += mtu;
      end += mtu;
      length -= mtu;
    }

    chunk = msg.sublist(start, start + length);
    await _reactiveBle.writeCharacteristicWithResponse(
      qChar, value: [BleUtils.MESSAGE_END] + chunk.toList()
    );
  }
}
