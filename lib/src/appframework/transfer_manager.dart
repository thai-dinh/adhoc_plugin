import 'dart:async';
import 'dart:collection';
import 'dart:core';
import 'dart:math' hide log;

import 'package:adhoclibrary/src/appframework/config.dart';
import 'package:adhoclibrary/src/datalink/exceptions/device_failure.dart';
import 'package:adhoclibrary/src/datalink/service/adhoc_device.dart';
import 'package:adhoclibrary/src/datalink/service/service.dart';
import 'package:adhoclibrary/src/datalink/utils/utils.dart';
import 'package:adhoclibrary/src/network/aodv/aodv_manager.dart';
import 'package:adhoclibrary/src/network/datalinkmanager/abstract_wrapper.dart';
import 'package:adhoclibrary/src/network/datalinkmanager/datalink_manager.dart';
import 'package:adhoclibrary/src/network/datalinkmanager/adhoc_event.dart';


class TransferManager {
  static const String TAG = '[AutoTransfer]';
  static const String PREFIX = '[PEER]';

  static const int MIN_DELAY_TIME = 2000;
  static const int MAX_DELAY_TIME = 5000;

  static const int INIT_STATE = 0;
  static const int DISCOVERY_STATE = 1;
  static const int CONNECT_STATE = 2;

  bool _verbose;
  Config _config;
  AodvManager _aodvManager;
  DataLinkManager _dataLinkManager;
  StreamController<AdHocEvent> _controller;

  int _state;
  Timer _timer;
  int _elapseTimeMax;
  int _elapseTimeMin;
  AdHocDevice _currentDevice;

  Set<String> _connectedDevices;
  List<AdHocDevice> _discoveredDevices;

  TransferManager(bool verbose, {Config config}) {
    this._verbose = verbose;
    this._config = config == null ? Config() : config;
    this._controller = StreamController<AdHocEvent>();
    this._connectedDevices = HashSet();
    this._discoveredDevices = List.empty(growable: true);
    this._state = INIT_STATE;
  }

  void start() {
    this._aodvManager = AodvManager(_verbose, _config);
    this._dataLinkManager = _aodvManager.dataLinkManager;
    this._dataLinkManager.eventStream.listen((event) {
      _controller.add(event);

      switch (event.type) {
        case AbstractWrapper.INTERNAL_EXCEPTION:
          // TODO: handle exception
          break;

        case AbstractWrapper.CONNECTION_EVENT:
          AdHocDevice device = event.payload as AdHocDevice;
          _connectedDevices.add(device.mac);
          _discoveredDevices.remove(device);
          _state = INIT_STATE;
          break;

        case AbstractWrapper.DISCONNECTION_EVENT:
          AdHocDevice device = event.payload as AdHocDevice;
          _connectedDevices.remove(device.mac);
          break;

        default:
          break;
      }
    });

    this._dataLinkManager.discoveryStream.listen((event) {
      switch (event.type) {
        case Service.DISCOVERY_STARTED:
          _state = DISCOVERY_STATE;
          break;

        case Service.DISCOVERY_END:
          (event.payload as Map<String, AdHocDevice>).forEach((mac, device) {
            if (device.name.contains(PREFIX) && !_connectedDevices.contains(mac)) {
              _discoveredDevices.add(device);
            }
          });

          _state = INIT_STATE;
          break;

        default:
          break;
      }
    });
  }

/*------------------------------Getters & Setters-----------------------------*/

  String get ownAddress => _config.label;

  Config get config => _config;

  Stream<AdHocEvent> get adHocEventStream => _controller.stream;

/*------------------------------Network methods------------------------------*/

  void sendMessageTo(Object message, AdHocDevice adHocDevice) {
    if (_dataLinkManager.checkState() == 0)
      throw DeviceFailureException('No wifi and bluetooth connectivity');
    _aodvManager.sendMessageTo(message, adHocDevice.label);
  }

  Future<bool> broadcast(Object message) async {
    if (_dataLinkManager.checkState() == 0)
      throw DeviceFailureException('No wifi and bluetooth connectivity');
    return await _dataLinkManager.broadcastObject(message);
  }

  Future<bool> broadcastExcept(Object message, AdHocDevice excludedDevice) async {
    if (_dataLinkManager.checkState() == 0)
      throw DeviceFailureException('No wifi and bluetooth connectivity');
    return await _dataLinkManager.broadcastObjectExcept(message, excludedDevice.label);
  }

/*------------------------------DataLink methods-----------------------------*/

  void startDiscovery() => _startDiscovery(50000, 60000);

  void _startDiscovery(int elapseTimeMin, int elapseTimeMax) {
    this._elapseTimeMin = elapseTimeMin;
    this._elapseTimeMax = elapseTimeMax;

    _updateAdapterName();
    _connectPairedDevices();
    _timerDiscovery(waitRandomTime(MIN_DELAY_TIME, MAX_DELAY_TIME));
    _timerConnect();
  }

  Future<void> _updateAdapterName() async {
    String name = await getBluetoothAdapterName();
    if (name != null && !name.contains(PREFIX))
      updateBluetoothAdapterName(PREFIX + name);

    name = await getWifiAdapterName();
    if (name != null && !name.contains(PREFIX))
      updateWifiAdapterName(PREFIX + name);
  }

  Future<void> _connectPairedDevices() async {
    HashMap<String, AdHocDevice> paired = await getPairedBluetoothDevices();
    if (paired != null) {
      for (AdHocDevice adHocDevice in paired.values) {
        log(TAG, 'Paired devices: ${adHocDevice.toString()}');
        if (!_connectedDevices.contains(adHocDevice.mac) 
          && adHocDevice.name.contains(PREFIX)) {
          _discoveredDevices.add(adHocDevice);
        }
      }
    }
  }

  void _timerDiscovery(int time) {
    Timer(Duration(milliseconds: time), () {
      if (_state == INIT_STATE) {
        log(TAG, 'START discovery');
        discovery();
        _timerDiscovery(waitRandomTime(_elapseTimeMin, _elapseTimeMax));
      } else {
        log(TAG, 'Unable to discovery ${_getStateString()}');
        _timerDiscovery(waitRandomTime(_elapseTimeMin, _elapseTimeMax));
      }
    });
  }

  String _getStateString() {
    switch (_state) {
      case DISCOVERY_STATE:
          return 'DISCOVERY';
      case CONNECT_STATE:
          return 'CONNECTING';
      case INIT_STATE:
      default:
          return 'INIT';
    }
  }

  void _timerConnect() {
    Timer.periodic(Duration(milliseconds: MAX_DELAY_TIME), (Timer timer) {
      Future.delayed(Duration(milliseconds: MIN_DELAY_TIME));
      for (AdHocDevice device in _discoveredDevices) {
        if (_state == INIT_STATE) {
          log(TAG, 'Try to connect to ${device.toString()}');
          _currentDevice = device;
          _state = CONNECT_STATE;
          connectOnce(device);
        }
      }
    });
  }

  int waitRandomTime(int min, int max) {
    return Random().nextInt(max - min + 1) + min;
  }

  Future<void> reset() async {
    String name = await getBluetoothAdapterName();
    if (name != null && name.contains(PREFIX))
      resetBluetoothAdapterName();

    name = await getWifiAdapterName();
    if (name != null && name.contains(PREFIX))
      resetWifiAdapterName();
  }

  void connect(int attempts, AdHocDevice adHocDevice) {
    if (_dataLinkManager.checkState() == 0)
      throw DeviceFailureException('No wifi and bluetooth connectivity');
    _dataLinkManager.connect(attempts, adHocDevice);
  }

  void connectOnce(AdHocDevice adHocDevice) {
    if (_dataLinkManager.checkState() == 0)
      throw DeviceFailureException('No wifi and bluetooth connectivity');
    _dataLinkManager.connect(1, adHocDevice);
  }

  void stopListening() {
    _dataLinkManager.stopListening();
  }

  void discovery() =>_dataLinkManager.discovery();

  void stopDiscovery() {
    if (_timer != null) {
      _timer.cancel();
      _timer = null;
    }
  }

  Future<HashMap<String, AdHocDevice>> getPairedBluetoothDevices() async {
    return _dataLinkManager.getPaired();
  }

  List<AdHocDevice> getDirectNeighbors() {
    return _dataLinkManager.getDirectNeighbors();
  }

  void enableAll(void Function(bool) onEnable) {
    _dataLinkManager.enableAll(onEnable);
  }

  void enableWifi(void Function(bool) onEnable) {
    _dataLinkManager.enable(0, Service.WIFI, onEnable);
  }

  void enableBluetooth(int duration, void Function(bool) onEnable) {
    _dataLinkManager.enable(duration, Service.BLUETOOTHLE, onEnable);
  }

  void disableAll() {
    _dataLinkManager.disableAll();
  }

  void disableWifi() {
    _dataLinkManager.disable(Service.WIFI);
  }

  void disableBluetooth() {
    _dataLinkManager.disable(Service.BLUETOOTHLE);
  }

  bool isWifiEnabled() {
      return _dataLinkManager.isEnabled(Service.WIFI);
  }

  bool isBluetoothEnabled() {
    return _dataLinkManager.isEnabled(Service.BLUETOOTHLE);
  }

  Future<bool> updateBluetoothAdapterName(String name) async {
    return await _dataLinkManager.updateAdapterName(Service.BLUETOOTHLE, name);
  }

  Future<bool> updateWifiAdapterName(String name) async {
    return await _dataLinkManager.updateAdapterName(Service.WIFI, name);
  }

  void resetBluetoothAdapterName() {
    _dataLinkManager.resetAdapterName(Service.BLUETOOTHLE);
  }

  void resetWifiAdapterName() {
    _dataLinkManager.resetAdapterName(Service.WIFI);
  }

  void removeWifiGroup() {
    _dataLinkManager.removeGroup();
  }

  bool isWifiGroupOwner() {
    return _dataLinkManager.isWifiGroupOwner();
  }

  Future<HashMap<int, String>> getActifAdapterNames() async {
    return await _dataLinkManager.getActifAdapterNames();
  }

  Future<String> getWifiAdapterName() async {
    return _dataLinkManager.getAdapterName(Service.WIFI);
  }

  Future<String> getBluetoothAdapterName() async {
    return _dataLinkManager.getAdapterName(Service.BLUETOOTHLE);
  }

  void disconnectAll() {
    _dataLinkManager.disconnectAll();
  }

  void disconnect(AdHocDevice adHocDevice) {
    _dataLinkManager.disconnect(adHocDevice.label);
  }
}

