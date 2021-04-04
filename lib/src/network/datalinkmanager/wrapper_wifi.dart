import 'dart:async';
import 'dart:collection';

import 'package:adhoc_plugin/src/appframework/config.dart';
import 'package:adhoc_plugin/src/datalink/service/adhoc_device.dart';
import 'package:adhoc_plugin/src/datalink/service/adhoc_event.dart';
import 'package:adhoc_plugin/src/datalink/service/discovery_event.dart';
import 'package:adhoc_plugin/src/datalink/service/service.dart';
import 'package:adhoc_plugin/src/datalink/utils/identifier.dart';
import 'package:adhoc_plugin/src/datalink/utils/msg_adhoc.dart';
import 'package:adhoc_plugin/src/datalink/utils/msg_header.dart';
import 'package:adhoc_plugin/src/datalink/utils/utils.dart';
import 'package:adhoc_plugin/src/datalink/wifi/wifi_adhoc_device.dart';
import 'package:adhoc_plugin/src/datalink/wifi/wifi_adhoc_manager.dart';
import 'package:adhoc_plugin/src/datalink/wifi/wifi_client.dart';
import 'package:adhoc_plugin/src/datalink/wifi/wifi_server.dart';
import 'package:adhoc_plugin/src/network/datalinkmanager/abstract_wrapper.dart';
import 'package:adhoc_plugin/src/network/datalinkmanager/flood_msg.dart';
import 'package:adhoc_plugin/src/network/datalinkmanager/network_manager.dart';
import 'package:adhoc_plugin/src/network/datalinkmanager/wrapper_conn_oriented.dart';


class WrapperWifi extends WrapperConnOriented {
  static const String TAG = "[WrapperWifi]";

  int _serverPort;
  String _ownIpAddress;
  String _groupOwnerAddr;
  bool _isDiscovering;
  bool _isGroupOwner;
  bool _isListening;
  bool _isConnecting;
  HashMap<String, String> _mapAddrMac;
  HashMap<String, WifiClient> _wifiClients;
  StreamSubscription<DiscoveryEvent> _discoverySub;
  WifiAdHocManager _wifiManager;

  WrapperWifi(
    bool verbose, Config config, HashMap<String, AdHocDevice> mapMacDevices
  ) : super(verbose, config, mapMacDevices) {
    this._isDiscovering = false;
    this._isGroupOwner = false;
    this._isListening = false;
    this._isConnecting = false;
    this._wifiClients = HashMap();
    this.ownMac = Identifier();
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
      this._wifiManager = WifiAdHocManager(verbose, _onWifiReady)..register(_registration);
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
    _wifiManager = WifiAdHocManager(verbose, _onWifiReady)..register(_registration);
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
  Future<void> connect(int attempts, AdHocDevice adHocDevice) async {
    WifiAdHocDevice wifiAdHocDevice = mapMacDevices[adHocDevice.mac.wifi];
    if (wifiAdHocDevice != null) {
      this.attempts = attempts;
      await _wifiManager.connect(adHocDevice.mac.wifi);
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
          mapMacDevices.putIfAbsent(device.mac.wifi, () {
            if (verbose) log(TAG, "Add " + device.mac.wifi + " into mapMacDevices");
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
      if (!_isConnecting) {
        _connect(_serverPort);
        _isConnecting = true;
      }
    }
  }

  void _onWifiReady(String ipAddress, String mac) {
    _ownIpAddress = ipAddress;
    ownMac.wifi = mac;
  }

  void _onEvent(Service service) {
    service.adhocEvent.listen((event) async { 
      switch (event.type) {
        case Service.MESSAGE_RECEIVED:
          _processMsgReceived(event.payload as MessageAdHoc);
          break;

        case Service.CONNECTION_PERFORMED:
          String remoteAddress = event.payload as String;
          WifiClient wifiClient = _wifiClients[remoteAddress];
          mapAddrNetwork.putIfAbsent(
            remoteAddress,
            () => NetworkManager(
              (MessageAdHoc msg) async => wifiClient.send(msg), 
              () => wifiClient.disconnect()
            )
          );

          ownName = await _wifiManager.adapterName;
          eventCtrl.add(AdHocEvent(AbstractWrapper.DEVICE_INFO_WIFI, [ownMac, ownName]));

          wifiClient.send(
            MessageAdHoc(
              Header(
                messageType: AbstractWrapper.CONNECT_SERVER,
                label: label,
                name: ownName,
                mac: ownMac,
                address: _ownIpAddress,
                deviceType: Service.WIFI
              ),
            )
          );
          break;

        case Service.CONNECTION_ABORTED:
          connectionClosed(_mapAddrMac[event.payload as String]);
          break;

        case Service.CONNECTION_EXCEPTION:
          eventCtrl.add(AdHocEvent(AbstractWrapper.INTERNAL_EXCEPTION, event.payload));
          break;

        default:
      }
    });
  }

  void _listenServer() {
    serviceServer = WifiServer(verbose)..listen(hostIp: _ownIpAddress, serverPort: _serverPort);
    _onEvent(serviceServer);
  }

  void _connect(int remotePort) async {
    final wifiClient = WifiClient(verbose, remotePort, _groupOwnerAddr, attempts, timeOut);
    await wifiClient.connect();
    _onEvent(wifiClient);

    _wifiClients.putIfAbsent(_groupOwnerAddr, () => wifiClient);
  }

  void _processMsgReceived(MessageAdHoc message) async {
    switch (message.header.messageType) {
      case AbstractWrapper.CONNECT_SERVER:
        String remoteAddress = message.header.address;
        _mapAddrMac.putIfAbsent(
          remoteAddress, () => message.header.mac.wifi
        );

        ownName = await _wifiManager.adapterName;
        eventCtrl.add(AdHocEvent(AbstractWrapper.DEVICE_INFO_WIFI, [ownMac, ownName]));

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
          message.header.address, () => message.header.mac.wifi
        );

        NetworkManager network = mapAddrNetwork[message.header.address];
        receivedPeerMessage(message.header, network);
        break;

      case AbstractWrapper.CONNECT_BROADCAST:
        FloodMsg floodMsg = FloodMsg.fromJson(message.pdu as Map);
        if (checkFloodEvent(floodMsg.id)) {
          broadcastExcept(message, message.header.label);

          HashSet<AdHocDevice> hashSet = floodMsg.adHocDevices;
          for (AdHocDevice device in hashSet) {
            if (device.label != label 
              && !setRemoteDevices.contains(device)
              && !isDirectNeighbors(device.label)
            ) {
              device.directedConnected = false;

              eventCtrl.add(AdHocEvent(AbstractWrapper.CONNECTION_EVENT, device));

              setRemoteDevices.add(device);
            }
          }
        }
        break;

      case AbstractWrapper.DISCONNECT_BROADCAST:
        if (checkFloodEvent(message.pdu as String)) {
          broadcastExcept(message, message.header.label);

          Header header = message.header;
          AdHocDevice adHocDevice = AdHocDevice(
            label: header.label,
            name: header.name,
            mac: header.mac,
            type: type, 
            directedConnected: false
          );

          eventCtrl.add(AdHocEvent(AbstractWrapper.DISCONNECTION_EVENT, adHocDevice));

          if (setRemoteDevices.contains(adHocDevice))
            setRemoteDevices.remove(adHocDevice);
        }
        break;

      case AbstractWrapper.BROADCAST:
        Header header = message.header;
        AdHocDevice adHocDevice = AdHocDevice(
          label: header.label,
          name: header.name,
          mac: header.mac,
          type: header.deviceType
        );

        eventCtrl.add(AdHocEvent(AbstractWrapper.DATA_RECEIVED, [adHocDevice, message.pdu]));
        break;

      default:
        eventCtrl.add(AdHocEvent(AbstractWrapper.MESSAGE_EVENT, message));
        break;
    }
  }
}
