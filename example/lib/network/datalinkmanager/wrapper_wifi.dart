import 'dart:async';
import 'dart:collection';

import 'package:adhoclibrary/adhoclibrary.dart' hide WifiAdHocDevice, WifiClient, WifiServer;
import 'package:adhoclibrary_example/datalink/wifi/wifi_adhoc_device.dart';
import 'package:adhoclibrary_example/datalink/wifi/wifi_client.dart';
import 'package:adhoclibrary_example/datalink/wifi/wifi_server.dart';


class WrapperWifi extends WrapperConnOriented {
  static const String TAG = "[WrapperWifi]";

  int _serverPort;
  String _ownIpAddress;
  String _groupOwnerAddr;
  bool _isDiscovering;
  HashMap<String, String> _mapAddrMac;

  int index;
  List<AdHocDevice> devices;

  WrapperWifi(
    bool verbose, Config config, HashMap<String, AdHocDevice> mapMacDevices,
    this.index, this.devices
  ) : super(verbose, config, mapMacDevices) {
    this._isDiscovering = false;
    this.type = Service.WIFI;
    this.ownName = devices[index].name;
    this.ownMac = devices[index].mac;
    this._ownIpAddress = (devices[index] as WifiAdHocDevice).port.toString();
    this._groupOwnerAddr = '127.0.0.1';
    this.init(verbose, config);
  }

/*------------------------------Getters & Setters-----------------------------*/

  bool get isGroupOwner => false;

/*------------------------------Override methods------------------------------*/

  @override
  void init(bool verbose, [Config config]) {
    for (int i = 0; i < devices.length; i++) {
      if (i != index)
        mapMacDevices.putIfAbsent(devices[i].mac, () => devices[i]);
    }

    this._serverPort = (devices[index] as WifiAdHocDevice).port;
    this._mapAddrMac = HashMap();
    this._listenServer();
    this.enabled = true;
  }

  @override
  void enable(int duration, void Function(bool) onEnable) {
    enabled = true;
  }

  @override 
  void disable() {
    mapAddrNetwork.clear();
    neighbors.clear();

    enabled = false;
  }

  @override
  void discovery() {
    if (_isDiscovering)
      return;

    _isDiscovering = true;
  }

  @override
  void connect(int attempts, AdHocDevice adHocDevice) async {
    WifiAdHocDevice wifiAdHocDevice = mapMacDevices[adHocDevice.mac];
    if (wifiAdHocDevice != null) {
      this.attempts = attempts;
      _connect(wifiAdHocDevice.port);
    }
  }

  @override
  void stopListening() {
    if (serviceServer != null) {
      serviceServer.stopListening();
    } 
  }

  @override // Not used in wifi context
  Future<HashMap<String, AdHocDevice>> getPaired() => null;

  @override
  Future<String> getAdapterName() async {
    return null;
  }

  @override
  Future<bool> updateDeviceName(final String name) async {
    return null;
  }

  @override
  Future<bool> resetDeviceName() async {
    return null;
  }

/*-------------------------------Public methods-------------------------------*/

  void unregister() { }

  void removeGroup() {
    if (serviceServer != null) {
      _mapAddrMac.forEach((address, mac) async {
        await serviceServer.cancelConnection(mac);
      });

      serviceServer.activeConnections.clear();
    }
  }

/*------------------------------Private methods-------------------------------*/

  void _onEvent(Service service) {
    service.connStatusStream.listen((ConnectionEvent info) {
      switch (info.status) {
        case Service.CONNECTION_CLOSED:
          connectionClosed(info.address);
          break;

        case Service.CONNECTION_PERFORMED:
          break;

        case Service.CONNECTION_EXCEPTION:
          eventCtrl.add(AdHocEvent(AbstractWrapper.INTERNAL_EXCEPTION, info.error));
          break;

        default:
          break;
      }
    });

    service.messageStream.listen((MessageAdHoc msg) => _processMsgReceived(msg));
  }

  void _listenServer() {
    serviceServer = WifiServer(verbose)..start(hostIp: '127.0.0.1', serverPort: _serverPort);
    _onEvent(serviceServer);
  }

  void _connect(int remotePort) async {
    final wifiClient = WifiClient(verbose, remotePort, _groupOwnerAddr, attempts, timeOut);

    wifiClient.connectListener = (String remoteAddress) async {
      _ownIpAddress = remoteAddress;
      print('client: ' + _ownIpAddress);
      mapAddrNetwork.putIfAbsent(
        remotePort.toString(),
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
          address: remoteAddress,
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
        FloodMsg floodMsg = FloodMsg.fromJson(message.pdu as Map);
        if (checkFloodEvent(floodMsg.id)) {
          broadcastExcept(message, message.header.label);

          HashSet<AdHocDevice> hashSet = floodMsg.adHocDevices;
          for (AdHocDevice adHocDevice in hashSet) {
            if (adHocDevice.label != label 
              && !setRemoteDevices.contains(adHocDevice)
              && !isDirectNeighbors(adHocDevice.label)
            ) {
              adHocDevice.directedConnected = false;

              eventCtrl.add(AdHocEvent(AbstractWrapper.CONNECTION_EVENT, adHocDevice));

              setRemoteDevices.add(adHocDevice);
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

        eventCtrl.add(
          AdHocEvent(
            AbstractWrapper.DATA_RECEIVED, 
            AdHocDevice(
              label: header.label,
              name: header.name,
              mac: header.mac,
              type: header.deviceType
            ),
            extra: message.pdu
          )
        );
        break;

      default:
        eventCtrl.add(AdHocEvent(AbstractWrapper.MESSAGE_EVENT, message));
        break;
    }
  }
}
