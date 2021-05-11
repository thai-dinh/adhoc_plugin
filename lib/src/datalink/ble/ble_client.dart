import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:adhoc_plugin/src/datalink/ble/ble_adhoc_device.dart';
import 'package:adhoc_plugin/src/datalink/ble/ble_adhoc_manager.dart';
import 'package:adhoc_plugin/src/datalink/exceptions/no_connection.dart';
import 'package:adhoc_plugin/src/datalink/service/adhoc_event.dart';
import 'package:adhoc_plugin/src/datalink/service/constants.dart' as Constants;
import 'package:adhoc_plugin/src/datalink/service/constants.dart';
import 'package:adhoc_plugin/src/datalink/service/service_client.dart';
import 'package:adhoc_plugin/src/datalink/utils/msg_adhoc.dart';
import 'package:adhoc_plugin/src/datalink/utils/utils.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';


class BleClient extends ServiceClient {
  static int id = 0;

  StreamSubscription<ConnectionStateUpdate>? _connnectionSub;
  StreamSubscription<List<int>>? _messageSub;
  late FlutterReactiveBle _reactiveBle;
  BleAdHocDevice _device;
  Stream<dynamic> _bondStream;
  late Uuid _serviceUuid;
  late Uuid _characteristicUuid;

  BleClient(
    bool verbose, this._device, int attempts, int? timeOut, this._bondStream
  ) : super(
    verbose, attempts, timeOut
  ) {
    this._reactiveBle = FlutterReactiveBle();
    this._serviceUuid = Uuid.parse(SERVICE_UUID);
    this._characteristicUuid = Uuid.parse(CHARACTERISTIC_UUID);
  }

/*-------------------------------Public methods-------------------------------*/

  void listen() {
    final qChar = QualifiedCharacteristic(
      serviceId: _serviceUuid,
      characteristicId: _characteristicUuid,
      deviceId: _device.mac!
    );

    List<Uint8List> bytesData = List.empty(growable: true);
    _messageSub = _reactiveBle.subscribeToCharacteristic(qChar).listen((rawData) {
      bytesData.add(Uint8List.fromList(rawData));
      if (rawData[0] == MESSAGE_END) {
        if (verbose) log(ServiceClient.TAG, 'Client: message received: ${_device.mac}');
        controller.add(AdHocEvent(Constants.MESSAGE_RECEIVED, processMessage(bytesData)));
        bytesData.clear();
      }
    }, onDone: () => _messageSub = null);
  }

  @override
  void stopListening() {
    super.stopListening();

    if (_connnectionSub != null)
      _connnectionSub!.cancel();
    if (_messageSub != null)
      _messageSub!.cancel();
  }

  Future<void> connect() => _connect(attempts, Duration(milliseconds: backOffTime));

  void disconnect() {
    this.stopListening();
    BleAdHocManager.cancelConnection(_device.mac);
  }

  Future<void> send(MessageAdHoc message) async {
    if (verbose) log(ServiceClient.TAG, 'Client: sendMessage() -> ${_device.mac}');

    if (state == Constants.STATE_NONE)
      throw NoConnectionException('No remote connection');

    int _id = id++;

    final characteristic = QualifiedCharacteristic(
      serviceId: _serviceUuid,
      characteristicId: _characteristicUuid,
      deviceId: _device.mac!
    );

    Uint8List msg = Utf8Encoder().convert(json.encode(message.toJson())), chunk;
    int mtu = _device.mtu - 5, length = msg.length, start = 0, end = mtu;

    while (length > mtu) {
      chunk = msg.sublist(start, end);
      List<int> tmp = [1, _id % UINT8_SIZE] + chunk.toList();
      await _reactiveBle.writeCharacteristicWithoutResponse(
        characteristic, value: tmp
      );

      start = end;
      end += mtu;
      length -= mtu;
    }

    chunk = msg.sublist(start, msg.length);
    List<int> tmp = [0, _id % UINT8_SIZE] + chunk.toList();
    await _reactiveBle.writeCharacteristicWithoutResponse(
      characteristic, value: tmp
    );
  }

/*------------------------------Private methods-------------------------------*/

  Future<void> _requestMtu() async {
    _device.mtu = await _reactiveBle.requestMtu(
      deviceId: _device.mac!, 
      mtu: MAX_MTU
    );
  }

  Future<void> _connect(int? attempts, Duration delay) async {
    try {
      await _connectionAttempt();
    } on NoConnectionException {
      if (attempts! > 0) {
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

    if (state == Constants.STATE_NONE || state == Constants.STATE_CONNECTING) {
      _connnectionSub = _reactiveBle.connectToDevice(
        id: _device.mac!,
        servicesWithCharacteristicsToDiscover: {},
        connectionTimeout: Duration(seconds: timeOut!),
      ).listen((event) async {
        switch (event.connectionState) {
          case DeviceConnectionState.connected:
            if (verbose)
              log(ServiceClient.TAG, 'Connected to ${_device.mac}');

            if (!(await (BleAdHocManager.getBondState(_device.mac) as Future<bool>))) {
              _bondStream.listen((event) async {
                if (_device.mac == event['macAddress']) {
                  listen();
                  await _requestMtu();

                  controller.add(AdHocEvent(Constants.CONNECTION_PERFORMED, [_device.mac, _device.uuid, 1]));

                  state = Constants.STATE_CONNECTED;
                }
              });

              BleAdHocManager.createBond(_device.mac);
            } else {
              listen();
              await _requestMtu();

              controller.add(AdHocEvent(Constants.CONNECTION_PERFORMED, [_device.mac, _device.uuid, 1]));

              state = Constants.STATE_CONNECTED;
            }
            break;

          case DeviceConnectionState.connecting:
            state = Constants.STATE_CONNECTING;
            break;

          default:
            state = Constants.STATE_NONE;
        }
      });
    }
  }
}
