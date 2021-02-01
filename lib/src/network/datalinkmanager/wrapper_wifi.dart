import 'dart:collection';

import 'package:adhoclibrary/src/appframework/config/config.dart';
import 'package:adhoclibrary/src/datalink/exceptions/device_failure.dart';
import 'package:adhoclibrary/src/datalink/service/adhoc_device.dart';
import 'package:adhoclibrary/src/datalink/service/discovery_listener.dart';
import 'package:adhoclibrary/src/datalink/service/service.dart';
import 'package:adhoclibrary/src/datalink/wifi/wifi_manager.dart';
import 'package:adhoclibrary/src/datalink/wifi/wifi_server.dart';
import 'package:adhoclibrary/src/network/datalinkmanager/wrapper_conn_oriented.dart';


class WrapperWifi extends WrapperConnOriented {
  int _serverPort;
  String _ownIpAddress;
  String _groupOwnerAddr;
  bool _isGroupOwner;
  WifiManager _wifiManager;
  HashMap<String, String> _mapAddrMac;

  WrapperWifi(
    bool verbose, Config config, HashMap<String, AdHocDevice> mapAddressDevice
  ) : super(verbose, config, mapAddressDevice) {
    this.type = Service.WIFI;
    this._init(verbose, config);
  }

/*------------------------------Override methods------------------------------*/

  @override
  void connect(int attempts, AdHocDevice adHocDevice) {
      String ip = _getIpByMac(adHocDevice.macAddress);
      if (ip == null) {
          this.attempts = attempts;
          _wifiManager.connect(adHocDevice.macAddress);
      } else {
          if (ip != null) { // TODO: change conditional
              this.attempts = attempts;
              _wifiManager.connect(adHocDevice.macAddress);
          } else {
              throw DeviceFailureException(adHocDevice.deviceName
                + '(' + adHocDevice.macAddress + ')' + 'is already connected');
          }
      }
  }

  @override
  void stopListening() {
    serviceServer.stopListening();
  }

  @override
  void discovery(DiscoveryListener discoveryListener) {
    DiscoveryListener listener = DiscoveryListener(
      onDeviceDiscovered: (AdHocDevice device) {
        mapMacDevices.putIfAbsent(device.macAddress, () => device);
        discoveryListener.onDeviceDiscovered(device);
      },

      onDiscoveryCompleted: (HashMap<String, AdHocDevice> mapNameDevice) {
        if (_wifiManager == null) {
          String msg = 'Discovery process failed due to wifi connectivity';
          discoveryListener.onDiscoveryFailed(DeviceFailureException(msg));
        } else {
          mapNameDevice.forEach((key, value) {
            mapMacDevices.putIfAbsent(key, () => value);
          });

          discoveryCompleted = true;
        }
      },

      onDiscoveryStarted: () {
        discoveryListener.onDiscoveryStarted();
      },
  
      onDiscoveryFailed: (Exception e) {
        discoveryListener.onDiscoveryFailed(e);
      }
    );

    _wifiManager.discovery(listener);
  }

  @override
  Future<HashMap<String, AdHocDevice>> getPaired() {
    return null; // Not used in wifi context
  }

  @override
  void enable(int duration) { // TODO: To verify bc enable wifi is deprecated
    _wifiManager = WifiManager(v);
    enabled = true;
  }

  @override 
  void disable() { // TODO: To verify bc disable wifi is deprecated
    _mapAddrMac.clear();
    _wifiManager = null;
    enabled = false;
  }

  @override
  Future<bool> resetDeviceName() async {
    return await _wifiManager.resetDeviceName();
  }

  @override
  Future<bool> updateDeviceName(String name) async {
    return await _wifiManager.updateDeviceName(name);
  }

  @override
  Future<String> getAdapterName() async {
    return await _wifiManager.getAdapterName();
  }

/*------------------------------WifiP2P methods-------------------------------*/

  void setGroupOwnerValue(int valueGroupOwner) {
    if (valueGroupOwner < 0 || valueGroupOwner > 15) {

    }
  }

  void removeGroup() {

  }

  void cancelConnect() {

  }

  bool isWifiGroupOwner() => _isGroupOwner;

/*------------------------------Private methods-------------------------------*/

  void _init(bool verbose, Config config) async {
    if (await WifiManager.isWifiEnabled()) {
      this._wifiManager = WifiManager(verbose);
      this._isGroupOwner = false;
      this._serverPort = config.serverPort;
      this._listenServer();
    } else {
      this.enabled = false;
    }
  }

  void _listenServer() {
    serviceServer = WifiServer(v, _serverPort)
      ..listen();
  }

  String _getIpByMac(String mac) {
    _mapAddrMac.forEach((key, value) {
      if (mac == value)
        return key;
    });

    return null;
  }
}
