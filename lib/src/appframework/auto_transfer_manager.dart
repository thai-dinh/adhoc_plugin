import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:adhoclibrary/src/appframework/config.dart';
import 'package:adhoclibrary/src/appframework/transfer_manager.dart';
import 'package:adhoclibrary/src/datalink/service/adhoc_device.dart';
import 'package:adhoclibrary/src/datalink/utils/utils.dart';


class AutoTransferManager extends TransferManager {
  static const String TAG = "[AutoTransfer]";
  static const String PREFIX = "[PEER]";

  static const int MIN_DELAY_TIME = 2000;
  static const int MAX_DELAY_TIME = 5000;

  static const int INIT_STATE = 0;
  static const int DISCOVERY_STATE = 1;
  static const int CONNECT_STATE = 2;

  Set<String> connectedDevices;
  List<AdHocDevice> discoveredDevices;

  int state;
  Timer timer;
  int elapseTimeMax;
  int elapseTimeMin;
  AdHocDevice currentDevice;

  AutoTransferManager(bool verbose, {Config config}) : super(verbose, config: config) {
    this.connectedDevices = HashSet();
    this.discoveredDevices = List();
    this.state = INIT_STATE;
  }

  void stopDiscovery() {
    if (timer != null) {
      timer.cancel();
      timer = null;
    }
  }

  void timerDiscovery(int time) {
    Timer(Duration(milliseconds: time), () {
      if (state == INIT_STATE) {
        log(TAG, "START discovery");
        // discovery((Event event) { });
        timerDiscovery(waitRandomTime(elapseTimeMin, elapseTimeMax));
      } else {
        log(TAG, "Unable to discovery " + getStateString());
        timerDiscovery(waitRandomTime(elapseTimeMin, elapseTimeMax));
      }
    });
  }

  int waitRandomTime(int min, int max) {
    return Random().nextInt(max - min + 1) + min;
  }

  Future<void> updateAdapterName() async {
    String name = await getBluetoothAdapterName();
    if (name != null && !name.contains(PREFIX))
      updateBluetoothAdapterName(PREFIX + name);

    name = await getWifiAdapterName();
    if (name != null && !name.contains(PREFIX))
      updateWifiAdapterName(PREFIX + name);
  }

  Future<void> connectPairedDevices() async {
    HashMap<String, AdHocDevice> paired = await getPairedBluetoothDevices();
    if (paired != null) {
      for (AdHocDevice adHocDevice in paired.values) {
        log(TAG, "Paired devices: " + adHocDevice.toString());
        if (!connectedDevices.contains(adHocDevice.mac) 
          && adHocDevice.name.contains(PREFIX)) {
          discoveredDevices.add(adHocDevice);
        }
      }
    }
  }

  void _startDiscovery(int elapseTimeMin, int elapseTimeMax) {
    this.elapseTimeMin = elapseTimeMin;
    this.elapseTimeMax = elapseTimeMax;

    updateAdapterName();
    connectPairedDevices();
    timerDiscovery(waitRandomTime(MIN_DELAY_TIME, MAX_DELAY_TIME));
    timerConnect();
  }

  void startDiscovery(int elapseTimeMin, int elapseTimeMax) {
    _startDiscovery(elapseTimeMin, elapseTimeMax);
  }

  void startDefaultDiscovery() {
    _startDiscovery(50000, 60000);
  }

  void timerConnect() {
    Timer.periodic(Duration(milliseconds: MAX_DELAY_TIME), (Timer timer) {
      Future.delayed(Duration(milliseconds: MIN_DELAY_TIME));
      for (AdHocDevice device in discoveredDevices) {
        if (state == INIT_STATE) {
          log(TAG, "Try to connect to " + device.toString());
          currentDevice = device;
          state = CONNECT_STATE;
          connectOnce(device);
        }
      }
    });
  }

  String getStateString() {
    switch (state) {
      case DISCOVERY_STATE:
          return "DISCOVERY";
      case CONNECT_STATE:
          return "CONNECTING";
      case INIT_STATE:
      default:
          return "INIT";
    }
  }

  Future<void> reset() async {
    String name = await getBluetoothAdapterName();
    if (name != null && name.contains(PREFIX))
      resetBluetoothAdapterName();

    name = await getWifiAdapterName();
    if (name != null && name.contains(PREFIX))
      resetWifiAdapterName();
  }
}
