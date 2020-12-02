import 'dart:collection';

import 'package:adhoclibrary/adhoclibrary.dart';

import 'package:flutter/material.dart';

void main() {
  runApp(ExampleApp());
}

class ExampleApp extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<ExampleApp> {
  BleManager _bleManager = BleManager();
  WifiManager _wifiManager = WifiManager();

  void _sendMessage() {
    HashMap<String, BleAdHocDevice> map = _bleManager.discoveredDevices;
    BleAdHocDevice device;

    map.forEach((key, value) { device = value; });

    BleMessageManager _msgManager = BleMessageManager(_bleManager, device);
    Header header = Header(0, 'hello', 'myPhone', 'myAddress');
    MessageAdHoc msg = MessageAdHoc(header, 'A message');

    _msgManager.sendMessage(msg);
  }

  void _requestMtu() {
    HashMap<String, BleAdHocDevice> map = _bleManager.discoveredDevices;
    BleAdHocDevice device;

    map.forEach((key, value) { device = value; });

    print('[MTU]: ' + device.mtu.toString() + ' [Device]: ' + device.macAddress);
    _bleManager.requestMtu(device, 50);
    print('[MTU]: ' + device.mtu.toString() + ' [Device]: ' + device.macAddress);
  }

  void _connect() {
    HashMap<String, BleAdHocDevice> map = _bleManager.discoveredDevices;
    String macAddress;

    map.forEach((key, value) { macAddress = key; });

    _bleManager.connect(macAddress);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              RaisedButton(
                child: Text('Start advertising'),
                onPressed: _bleManager.startAdvertise,
              ),
              RaisedButton(
                child: Text('Stop advertising'),
                onPressed: _bleManager.stopAdvertise,
              ),
              RaisedButton(
                child: Text('Start scan'),
                onPressed: _bleManager.startScan,
              ),
              RaisedButton(
                child: Text('Stop scan'),
                onPressed: _bleManager.stopScan,
              ),
              RaisedButton(
                child: Text('BLE Connect'),
                onPressed: _connect,
              ),
              RaisedButton(
                child: Text('Request MTU'),
                onPressed: _requestMtu,
              ),
              RaisedButton(
                child: Text('Start discovery'),
                onPressed: _wifiManager.startDiscovery,
              ),
              RaisedButton(
                child: Text('Stop discovery'),
                onPressed: _wifiManager.stopDiscovery,
              ),
              RaisedButton(
                child: Text('Connect'),
                onPressed: _wifiManager.connect,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
