import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:adhoclibrary/src/datalink/ble/ble_adhoc_device.dart';
import 'package:adhoclibrary/src/datalink/ble/ble_adhoc_manager.dart';
import 'package:adhoclibrary/src/datalink/ble/ble_constants.dart';
import 'package:adhoclibrary/src/datalink/exceptions/no_connection.dart';
import 'package:adhoclibrary/src/datalink/service/connection_event.dart';
import 'package:adhoclibrary/src/datalink/service/service.dart';
import 'package:adhoclibrary/src/datalink/service/service_client.dart';
import 'package:adhoclibrary/src/datalink/utils/msg_adhoc.dart';
import 'package:adhoclibrary/src/datalink/utils/utils.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';


class BleClient extends ServiceClient {
  StreamController<ConnectionEvent> _controller;
  StreamSubscription<ConnectionStateUpdate> _subscription;
  FlutterReactiveBle _reactiveBle;
  BleAdHocDevice _device;
  Uuid _serviceUuid;
  Uuid _characteristicUuid;

  void Function(String, String) _connectListener;

  BleClient(
    bool verbose, this._device, int attempts, int timeOut,
  ) : super(
    verbose, Service.STATE_NONE, attempts, timeOut
  ) {
    this._controller = StreamController<ConnectionEvent>();
    this._reactiveBle = FlutterReactiveBle();
    this._serviceUuid = Uuid.parse(SERVICE_UUID);
    this._characteristicUuid = Uuid.parse(CHARACTERISTIC_UUID);
  }

/*------------------------------Getters & Setters-----------------------------*/

  set connectListener(void Function(String, String) connectListener) {
    this._connectListener = connectListener;
  }

  Stream<ConnectionEvent> get connStatusStream async* {
    await for (ConnectionEvent status in _controller.stream) {
      yield status;
    }
  }

  Stream<MessageAdHoc> get messageStream async* {
    final qChar = QualifiedCharacteristic(
      serviceId: _serviceUuid,
      characteristicId: _characteristicUuid,
      deviceId: _device.mac
    );

    List<Uint8List> bytesData = List.empty(growable: true);
    await for (List<int> rawData in _reactiveBle.subscribeToCharacteristic(qChar)) {
      bytesData.add(Uint8List.fromList(rawData));
      if (rawData[0] == MESSAGE_END) {
        if (verbose) log(ServiceClient.TAG, 'Client: message received');
        yield processMessage(bytesData);
        bytesData.clear();
      }
    }
  }

/*-------------------------------Public methods-------------------------------*/

  void connect() => _connect(attempts, Duration(milliseconds: backOffTime));

  void disconnect() {
    if (_subscription != null)
      _subscription.cancel();

    BleAdHocManager.cancelConnection(_device.mac);

    _controller.add(ConnectionEvent(Service.CONNECTION_CLOSED, address: _device.address));
  }

  Future<void> send(MessageAdHoc message) async {
    if (verbose) log(ServiceClient.TAG, 'Client: sendMessage() -> ${_device.mac}');

    if (state == Service.STATE_NONE)
      throw NoConnectionException('No remote connection');

    final characteristic = QualifiedCharacteristic(
      serviceId: _serviceUuid,
      characteristicId: _characteristicUuid,
      deviceId: _device.mac
    );

    Uint8List msg = Utf8Encoder().convert(json.encode(message.toJson())), chunk;
    int mtu = _device.mtu - 10, length = msg.length, start = 0, end = mtu;
    int index = MESSAGE_BEGIN;

    while (length > mtu) {
      chunk = msg.sublist(start, end);
      List<int> tmp = [index % UINT8_SIZE] + chunk.toList();
      await _reactiveBle.writeCharacteristicWithoutResponse(
        characteristic, value: tmp
      );

      index++;
      start = end;
      end += mtu;
      length -= mtu;
    }

    chunk = msg.sublist(start, msg.length);
    List<int> tmp = [MESSAGE_END] + chunk.toList();
    await _reactiveBle.writeCharacteristicWithoutResponse(
      characteristic, value: tmp
    );
  }

/*------------------------------Private methods-------------------------------*/

  Future<void> _requestMtu() async {
    _device.mtu = await _reactiveBle.requestMtu(
      deviceId: _device.mac, 
      mtu: MAX_MTU
    );
  }

  Future<void> _connect(int attempts, Duration delay) async {
    try {
      await _connectionAttempt();
    } on NoConnectionException {
      if (attempts > 0) {
        if (verbose)
          log(ServiceClient.TAG, 'Connection attempt $attempts failed');
        
        await Future.delayed(delay);
        return _connect(attempts - 1, delay * 2);
      }

      rethrow;
    }
  }

  Future<void> _connectionAttempt() async {
    if (verbose) log(ServiceClient.TAG, 'Connect to ${_device.mac}');

    if (state == Service.STATE_NONE || state == Service.STATE_CONNECTING) {
      _subscription = _reactiveBle.connectToDevice(
        id: _device.mac,
        servicesWithCharacteristicsToDiscover: {},
        connectionTimeout: Duration(seconds: timeOut),
      ).listen((event) async {
        switch (event.connectionState) {
          case DeviceConnectionState.connected:
            if (verbose)
              log(ServiceClient.TAG, 'Connected to ${_device.mac}');
            await _requestMtu();

            _controller.add(ConnectionEvent(Service.CONNECTION_PERFORMED, address: _device.mac));

            if (_connectListener != null)
              _connectListener(_device.mac, _device.uuid);

            state = Service.STATE_CONNECTED;
            break;

          case DeviceConnectionState.connecting:
            state = Service.STATE_CONNECTING;
            break;

          default:
            state = Service.STATE_NONE;
        }
      });
    }
  }
}
