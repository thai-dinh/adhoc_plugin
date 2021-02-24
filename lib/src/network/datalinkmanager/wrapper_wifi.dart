import 'dart:async';
import 'dart:collection';

import 'package:adhoclibrary/src/appframework/config.dart';
import 'package:adhoclibrary/src/datalink/service/adhoc_device.dart';
import 'package:adhoclibrary/src/datalink/service/connect_status.dart';
import 'package:adhoclibrary/src/datalink/service/discovery_event.dart';
import 'package:adhoclibrary/src/datalink/service/service.dart';
import 'package:adhoclibrary/src/datalink/utils/msg_adhoc.dart';
import 'package:adhoclibrary/src/datalink/utils/msg_header.dart';
import 'package:adhoclibrary/src/datalink/utils/utils.dart';
import 'package:adhoclibrary/src/datalink/wifi/wifi_adhoc_device.dart';
import 'package:adhoclibrary/src/datalink/wifi/wifi_adhoc_manager.dart';
import 'package:adhoclibrary/src/datalink/wifi/wifi_client.dart';
import 'package:adhoclibrary/src/datalink/wifi/wifi_server.dart';
import 'package:adhoclibrary/src/network/datalinkmanager/abstract_wrapper.dart';
import 'package:adhoclibrary/src/network/datalinkmanager/flood_msg.dart';
import 'package:adhoclibrary/src/network/datalinkmanager/network_manager.dart';
import 'package:adhoclibrary/src/network/datalinkmanager/wrapper_conn_oriented.dart';
import 'package:adhoclibrary/src/network/datalinkmanager/wrapper_event.dart';


class WrapperWifi extends WrapperConnOriented {
  static const String TAG = "[WrapperWifi]";

  int _serverPort;
  String _ownIpAddress;
  String _groupOwnerAddr;
  bool _isDiscovering;
  bool _isGroupOwner;
  bool _isListening;
  HashMap<String, String> _mapAddrMac;
  StreamSubscription<DiscoveryEvent> _discoverySub;
  WifiAdHocManager _wifiManager;

  WrapperWifi(
    bool verbose, Config config, HashMap<String, AdHocDevice> mapMacDevices
  ) : super(verbose, config, mapMacDevices) {
    this._isDiscovering = false;
    this._isListening = false;
    this.type = Service.WIFI;
    this.init(verbose, config);
  }

/*------------------------------Getters & Setters-----------------------------*/

  bool get isGroupOwner => _isGroupOwner;

/*------------------------------Override methods------------------------------*/

  @override
  void init(bool verbose, [Config config]) async {
    _serverPort = config.serverPort;

    if (await WifiAdHocManager.isWifiEnabled()) {
      this._wifiManager = WifiAdHocManager(verbose, _onWifiReady)
        ..register(_registration);
      this._isGroupOwner = false;
      this._mapAddrMac = HashMap();
      this.ownName = await _wifiManager.adapterName;
      this._initialize();
      this.enabled = true;
    } else {
      this.enabled = false;
    }
  }

  @override
  void enable(int duration, void Function(bool) onEnable) {
    _wifiManager = WifiAdHocManager(verbose, _onWifiReady)
      ..register(_registration);
    _wifiManager.onEnableWifi(onEnable);

    enabled = true;
  }

  @override 
  void disable() {
    mapAddrNetwork.clear();
    neighbors.clear();

    _wifiManager = null;

    enabled = false;
  }

  @override
  void discovery() {
    if (_isDiscovering)
      return;

    _discoverySub.resume();
    _wifiManager.discovery();
    _isDiscovering = true;
  }

  @override
  void connect(int attempts, AdHocDevice adHocDevice) async {
    WifiAdHocDevice wifiAdHocDevice = mapMacDevices[adHocDevice.mac];
    if (wifiAdHocDevice != null) {
      this.attempts = attempts;
      await _wifiManager.connect(adHocDevice.mac);
    }
  }

  @override
  void stopListening() {
    if (serviceServer != null) {
      serviceServer.stopListening();
      _isListening = false;
    } 
  }

  @override // Not used in wifi context
  Future<HashMap<String, AdHocDevice>> getPaired() => null;

  @override
  Future<String> getAdapterName() async {
    return await _wifiManager.adapterName;
  }

  @override
  Future<bool> updateDeviceName(final String name) async {
    return await _wifiManager.updateDeviceName(name);
  }

  @override
  Future<bool> resetDeviceName() async {
    return await _wifiManager.resetDeviceName();
  }

/*-------------------------------Public methods-------------------------------*/

  void unregister() => _wifiManager.unregister();

  void removeGroup() {
    if (serviceServer != null) {
      _mapAddrMac.forEach((address, mac) async {
        await serviceServer.cancelConnection(mac);
      });

      serviceServer.activeConnections.clear();
    }

    _wifiManager.removeGroup();
  }

  bool isWifiGroupOwner() => _isGroupOwner;

/*------------------------------Private methods-------------------------------*/

  void _initialize() {
    _discoverySub = _wifiManager.discoveryStream.listen((DiscoveryEvent event) {
      discoveryCtrl.add(event);

      switch (event.type) {
        case Service.DEVICE_DISCOVERED:
          WifiAdHocDevice device = event.payload as WifiAdHocDevice;
          mapMacDevices.putIfAbsent(device.mac, () {
            if (verbose) log(TAG, "Add " + device.mac + " into mapMacDevices");
            return device;
          });
          break;

        case Service.DISCOVERY_END:
          if (verbose) log(TAG, 'Discovery end');
          (event.payload as Map).forEach((mac, device) {
            mapMacDevices.putIfAbsent(mac, () {
              if (verbose) log(TAG, "Add " + mac + " into mapMacDevices");
              return device;
            });
          });

          discoveryCompleted = true;
          _isDiscovering = false;
          _discoverySub.pause();
          break;

        default:
          break;
      }
    });

    _discoverySub.pause();
  }

  void _registration(
    bool isConnected, bool isGroupOwner, String groupOwnerAddress
  ) {
    _isGroupOwner = isGroupOwner;
    if (isConnected && _isGroupOwner) {
      _groupOwnerAddr = _ownIpAddress = groupOwnerAddress;
      if (!_isListening) {
        _listenServer();
        _isListening = true;
      }
    } else if (isConnected && !_isGroupOwner) {
      _groupOwnerAddr = groupOwnerAddress;
      _connect(_serverPort);
    }
  }

  void _onWifiReady(String ipAddress, String mac) {
    _ownIpAddress = ipAddress;
    ownMac = mac;
  }

  void _onEvent(Service service) {
    service.connStatusStream.listen((ConnectStatus info) {
      switch (info.status) {
        case Service.CONNECTION_CLOSED:
          connectionClosed(info.address);
          break;

        case Service.CONNECTION_PERFORMED:
          break;

        case Service.CONNECTION_EXCEPTION:
          break;

        default:
          break;
      }
    });

    service.messageStream.listen((MessageAdHoc msg) => _processMsgReceived(msg));
  }

  void _listenServer() {
    serviceServer = WifiServer(verbose)..start(hostIp: _ownIpAddress, serverPort: _serverPort);
    _onEvent(serviceServer);
  }

  void _connect(int remotePort) async {
    final wifiClient = WifiClient(verbose, remotePort, _groupOwnerAddr, attempts, timeOut);

    wifiClient.connectListener = (String remoteAddress) async {
      mapAddrNetwork.putIfAbsent(
        remoteAddress,
        () => NetworkManager(
          (MessageAdHoc msg) async => wifiClient.send(msg), 
          () => wifiClient.disconnect()
        )
      );

      wifiClient.send(MessageAdHoc(
        Header(
          messageType: AbstractWrapper.CONNECT_SERVER,
          label: label,
          name: ownName,
          mac: ownMac,
          address: _ownIpAddress,
          deviceType: Service.WIFI
        ),
      ));
    };

    await wifiClient.connect();
    _onEvent(wifiClient);
  }

  void _processMsgReceived(MessageAdHoc message) {
    print(message.toString());
    switch (message.header.messageType) {
      case AbstractWrapper.CONNECT_SERVER:
        String remoteAddress = message.header.address;

        serviceServer.send(
          MessageAdHoc(Header(
            messageType: AbstractWrapper.CONNECT_CLIENT,
            label: label,
            name: ownName,
            mac: ownMac,
            address: _ownIpAddress,
            deviceType: type
          )),
          remoteAddress
        );

        receivedPeerMessage(
          message.header,
          NetworkManager(
            (MessageAdHoc msg) => serviceServer.send(msg, remoteAddress),
            () => serviceServer.cancelConnection(remoteAddress)
          )
        );
        break;

      case AbstractWrapper.CONNECT_CLIENT:
        _mapAddrMac.putIfAbsent(
          message.header.address, () => message.header.mac
        );

        NetworkManager network = mapAddrNetwork[message.header.address];
        receivedPeerMessage(message.header, network);
        break;

      case AbstractWrapper.CONNECT_BROADCAST:
        if (checkFloodEvent((message.pdu as FloodMsg).id)) {
          broadcastExcept(message, message.header.label);

          HashSet<AdHocDevice> hashSet = (message.pdu as FloodMsg).adHocDevices;

          for (AdHocDevice adHocDevice in hashSet) {
            if (adHocDevice.label == label 
              && !setRemoteDevices.contains(adHocDevice)
              && !isDirectNeighbors(adHocDevice.label)
            ) {
              adHocDevice.directedConnected = false;
              setRemoteDevices.add(adHocDevice);
            }
          }
        }
        break;

      case AbstractWrapper.DISCONNECT_BROADCAST:
        if (checkFloodEvent(message.pdu as String))
          broadcastExcept(message, message.header.label);
        break;

      case AbstractWrapper.BROADCAST:
        break;

      default:
        break;
    }
  }
}
