import 'dart:collection';

import 'package:adhoclibrary/src/appframework/config.dart';
import 'package:adhoclibrary/src/appframework/listener_adapter.dart';
import 'package:adhoclibrary/src/appframework/listener_app.dart';
import 'package:adhoclibrary/src/datalink/exceptions/device_failure.dart';
import 'package:adhoclibrary/src/datalink/service/adhoc_device.dart';
import 'package:adhoclibrary/src/datalink/service/discovery_event.dart';
import 'package:adhoclibrary/src/datalink/service/service_client.dart';
import 'package:adhoclibrary/src/datalink/service/service.dart';
import 'package:adhoclibrary/src/datalink/utils/msg_adhoc.dart';
import 'package:adhoclibrary/src/datalink/utils/msg_header.dart';
import 'package:adhoclibrary/src/datalink/wifi/wifi_adhoc_device.dart';
import 'package:adhoclibrary/src/datalink/wifi/wifi_adhoc_manager.dart';
import 'package:adhoclibrary/src/datalink/wifi/wifi_client.dart';
import 'package:adhoclibrary/src/datalink/wifi/wifi_server.dart';
import 'package:adhoclibrary/src/network/datalinkmanager/abstract_wrapper.dart';
import 'package:adhoclibrary/src/network/datalinkmanager/flood_msg.dart';
import 'package:adhoclibrary/src/network/datalinkmanager/wrapper_conn_oriented.dart';


class WrapperWifi extends WrapperConnOriented {
  int _serverPort;
  String _ownIpAddress;
  String _groupOwnerAddr;
  bool _isGroupOwner;
  WifiAdHocManager _wifiManager;
  HashMap<String, String> _mapAddrMac;

  WrapperWifi(
    bool verbose, Config config, HashMap<String, AdHocDevice> mapAddressDevice,
    ListenerApp listenerApp
  ) : super(verbose, config, mapAddressDevice, listenerApp) {
    this.type = Service.WIFI;
    this.init(verbose, config);
  }

/*------------------------------Override methods------------------------------*/

  @override
  void init(bool verbose, [Config config]) async {
    if (await WifiAdHocManager.isWifiEnabled()) {
      this._wifiManager = WifiAdHocManager(verbose, _onWifiReady)..register(
        (bool isConnected, bool isGroupOwner, String groupOwnerAddress) {
          _isGroupOwner = isGroupOwner;
          if (isConnected && _isGroupOwner) {
            _groupOwnerAddr = _ownIpAddress = groupOwnerAddress;
            _listenServer();
          } else if (isConnected && !_isGroupOwner) {
            _groupOwnerAddr = groupOwnerAddress;
            _connect(config.serverPort);
          }
        }
      );

      this._isGroupOwner = false;
      this._mapAddrMac = HashMap();
      this._serverPort = config.serverPort;
    } else {
      this.enabled = false;
    }
  }

  @override
  void enable(int duration, ListenerAdapter listenerAdapter) { // TODO: To verify bc enable wifi is deprecated
    _wifiManager = WifiAdHocManager(v, _onWifiReady);
    _wifiManager.onEnableWifi(listenerAdapter);
    enabled = true;
  }

  @override 
  void disable() { // TODO: To verify bc disable wifi is deprecated
    _mapAddrMac.clear();
    neighbors.clear();

    _wifiManager = null;
    enabled = false;
  }

  @override
  void discovery(
    void onEvent(DiscoveryEvent event), void onError(dynamic error),
  ) {
    _wifiManager.discovery((DiscoveryEvent event) {
      onEvent(event);

      if (event.type == Service.DEVICE_DISCOVERED) {
        WifiAdHocDevice device = event.payload as WifiAdHocDevice;
        mapMacDevices.putIfAbsent(device.mac, () => device);
      } else if (event.type == Service.DISCOVERY_END) {
        HashMap<String, AdHocDevice> discoveredDevices = 
          event.payload as HashMap<String, AdHocDevice>;

          discoveredDevices.forEach((mac, device) {
            mapMacDevices.putIfAbsent(mac, () => device);
          });

          discoveryCompleted = true;
      }
    }, onError);
  }

  @override
  void connect(int attempts, AdHocDevice adHocDevice) async {
    this.attempts = attempts;
    
    if (!(await _wifiManager.connect(adHocDevice.mac))) {
      throw DeviceFailureException(
        adHocDevice.name + '(' + adHocDevice.mac + ')' + ': Connection failed'
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

  void removeGroup() => _wifiManager.removeGroup();

  bool isWifiGroupOwner() => _isGroupOwner;

/*------------------------------Private methods-------------------------------*/

  void _onWifiReady(String ipAddress) => _ownIpAddress = ipAddress;

  void _onEvent(DiscoveryEvent event) {
    switch (event.type) {
      case Service.MAC_EXCHANGE_SERVER:
        MessageAdHoc message = event.payload as MessageAdHoc;
        ownMac = message.pdu as String;
        serviceServer.sendMacAddress(message.header.mac);
        break;

      case Service.MAC_EXCHANGE_CLIENT:
        MessageAdHoc message = event.payload as MessageAdHoc;
        ownMac = message.pdu as String;
        break;

      case Service.MESSAGE_RECEIVED:
        _processMsgReceived(event.payload as MessageAdHoc);
        break;

      case Service.CONNECTION_PERFORMED:
        break;

      case Service.CONNECTION_CLOSED:
        connectionClosed(event.payload as String);
        break;
    }
  }

  void _onError(dynamic error) => print(error.toString());

  void _listenServer() {
    serviceServer = WifiServer(v, _onEvent, _onError)..listen(
      serverPort: _serverPort
    );
  }

  void _connect(int remotePort) {
    final wifiClient = WifiClient(
      v, remotePort, _groupOwnerAddr, attempts, timeOut, _onEvent, _onError
    );

    wifiClient.connectListener = (String remoteAddress) async {
      await wifiClient.send(MessageAdHoc(
        Header(messageType: Service.MAC_EXCHANGE_SERVER),
        remoteAddress
      ));

      await wifiClient.send(MessageAdHoc(
        Header(
          messageType: AbstractWrapper.CONNECT_SERVER,
          label: label,
          name: ownName,
          mac: ownMac,
          address: _ownIpAddress
        ),
        remoteAddress
      ));
    };

    wifiClient..connect()..listen();
  }

  void _processMsgReceived(MessageAdHoc message) {
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
        ServiceClient serviceClient = mapAddrClient[message.header.address];
        if (serviceClient != null) {
          _mapAddrMac.putIfAbsent(
            message.header.address, () => message.header.mac
          );

          receivedPeerMessage(message.header, serviceClient);
        }
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

              listenerApp.onConnection(adHocDevice);

              setRemoteDevices.add(adHocDevice);
            }
          }
        }
        break;

      case AbstractWrapper.DISCONNECT_BROADCAST:
        if (checkFloodEvent(message.pdu as String)) {
          broadcastExcept(message, message.header.label);
          Header header = message.header;

          listenerApp.onConnectionClosed(AdHocDevice(
            name: header.name,
            label: header.label,
            mac: header.mac,
            type: type,
            directedConnected: false
          ));
        }
        break;

      case AbstractWrapper.BROADCAST:
        Header header = message.header;

        listenerApp.onReceivedData(
          AdHocDevice(
            name: header.name,
            label: header.label,
            mac: header.mac,
            type: type,
          ),
          message.pdu
        );
        break;
      
      default:
    }
  }
}
