import 'dart:collection';

import 'package:adhoclibrary/src/appframework/config/config.dart';
import 'package:adhoclibrary/src/datalink/exceptions/device_failure.dart';
import 'package:adhoclibrary/src/datalink/service/adhoc_device.dart';
import 'package:adhoclibrary/src/datalink/service/discovery_listener.dart';
import 'package:adhoclibrary/src/datalink/service/service_msg_listener.dart';
import 'package:adhoclibrary/src/datalink/service/service.dart';
import 'package:adhoclibrary/src/datalink/utils/msg_adhoc.dart';
import 'package:adhoclibrary/src/datalink/utils/msg_header.dart';
import 'package:adhoclibrary/src/datalink/wifi/wifi_client.dart';
import 'package:adhoclibrary/src/datalink/wifi/wifi_manager.dart';
import 'package:adhoclibrary/src/datalink/wifi/wifi_server.dart';
import 'package:adhoclibrary/src/network/datalinkmanager/abstract_wrapper.dart';
import 'package:adhoclibrary/src/network/datalinkmanager/iwifi_p2p.dart';
import 'package:adhoclibrary/src/network/datalinkmanager/wrapper_conn_oriented.dart';


class WrapperWifi extends WrapperConnOriented implements IWifiP2P {
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
  void enable(final int duration) { // TODO: To verify bc enable wifi is deprecated
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
  void discovery(final DiscoveryListener discoveryListener) {
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

          discoveryListener.onDiscoveryCompleted(mapNameDevice);

          discoveryCompleted = true;
        }
      },

      onDiscoveryStarted: () {
        discoveryListener.onDiscoveryStarted();
      },
  
      onDiscoveryFailed: (Exception exception) {
        discoveryListener.onDiscoveryFailed(exception);
      }
    );

    _wifiManager.discovery(listener);
  }

  @override
  void connect(final int attempts, final AdHocDevice adHocDevice) async {
    this.attempts = attempts;
    
    if (!(await _wifiManager.connect(adHocDevice.macAddress))) {
      throw DeviceFailureException(adHocDevice.deviceName + '(' + 
        adHocDevice.macAddress + ')' + 'is already connected'
      );
    }
  }

  @override
  void stopListening() {
    if (serviceServer != null)
      serviceServer.stopListening();
  }

  @override // Not used in wifi context
  Future<HashMap<String, AdHocDevice>> getPaired() => null;

  @override
  Future<String> getAdapterName() async {
    return await _wifiManager.getAdapterName();
  }

  @override
  Future<bool> updateDeviceName(final String name) async {
    return await _wifiManager.updateDeviceName(name);
  }

  @override
  Future<bool> resetDeviceName() async {
    return await _wifiManager.resetDeviceName();
  }

/*------------------------------WifiP2P methods-------------------------------*/

  @override
  void setGroupOwnerValue(final int valueGroupOwner) {
    if (valueGroupOwner < 0 || valueGroupOwner > 15) {

    }
  }

  @override
  void removeGroup() => _wifiManager.removeGroup();

  @override
  void cancelConnect() {

  }

  @override
  bool isWifiGroupOwner() => _isGroupOwner;

/*------------------------------Private methods-------------------------------*/

  void _init(final bool verbose, final Config config) async {
    if (await WifiManager.isWifiEnabled()) {
      this._wifiManager = WifiManager(verbose)
      ..register((bool isGroupOwner, String groupOwnerAddress) {
        if (_isGroupOwner = isGroupOwner) {
          _groupOwnerAddr = _ownIpAddress = groupOwnerAddress;
          _listenServer();
        } else {
          _groupOwnerAddr = groupOwnerAddress;
          _connect(_serverPort);
        }
      });
      this._isGroupOwner = false;
      this._mapAddrMac = HashMap();
      this._serverPort = config.serverPort;
    } else {
      this.enabled = false;
    }
  }

  void _listenServer() {
    ServiceMessageListener listener = ServiceMessageListener(
      onMessageReceived: (MessageAdHoc message) {
        _processMsgReceived(message);
      },

      onConnectionClosed: (String remoteAddress) { },

      onConnection: (String remoteAddress) { },
  
      onConnectionFailed: (Exception exception) { },

      onMsgException: (Exception exception) { }
    );

    serviceServer = WifiServer(v, listener)..listen(_serverPort);
  }

  void _connect(final int remotePort) {
    ServiceMessageListener listener = ServiceMessageListener(
      onMessageReceived: (MessageAdHoc message) {
        _processMsgReceived(message);
      },

      onConnectionClosed: (String remoteAddress) { },

      onConnection: (String remoteAddress) { }, // Ignored
  
      onConnectionFailed: (Exception exception) { },

      onMsgException: (Exception exception) { }
    );

    final WifiClient wifiClient = WifiClient(
      v, remotePort, _groupOwnerAddr, attempts, timeOut, listener
    );

    wifiClient.connectListener = (String remoteAddress) {
      wifiClient.send(MessageAdHoc(
        Header(
          messageType: AbstractWrapper.CONNECT_SERVER,
          label: label,
          name: ownName,
          address: _ownIpAddress
        ),
        remoteAddress
      ));
    };

    wifiClient.connect();
  }

  void _processMsgReceived(final MessageAdHoc message) {
    switch (message.header.messageType) {
      case AbstractWrapper.CONNECT_SERVER:
        serviceServer.send(
          MessageAdHoc(Header(
            messageType: AbstractWrapper.CONNECT_CLIENT,
            label: label,
            name: ownName,
            address: _ownIpAddress
          )),
          null
        );
        break;

      case AbstractWrapper.CONNECT_CLIENT:
        break;

      case AbstractWrapper.CONNECT_BROADCAST:
        break;

      case AbstractWrapper.DISCONNECT_BROADCAST:
        break;

      case AbstractWrapper.BROADCAST:
        break;
      
      default:
    }
  }
}
