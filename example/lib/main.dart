import 'package:adhoclibrary_example/ble_client_example.dart';
import 'package:adhoclibrary_example/wifi_client_example.dart';

import 'package:flutter/material.dart';

void main() {
  runApp(ExampleApp());
}

class ExampleApp extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<ExampleApp> {
  BleClientExample example = BleClientExample();
  WifiClientExample wifiExample = WifiClientExample();

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
                child: Text('Start discovery'),
                onPressed: wifiExample.startDiscoveryExample,
              ),
              RaisedButton(
                child: Text('Stop discovery'),
                onPressed: wifiExample.stopDiscoveryExample,
              ),
              RaisedButton(
                child: Text('Connect'),
                onPressed: wifiExample.connectExample,
              ),
              RaisedButton(
                child: Text('Host'),
                onPressed: wifiExample.hostExample,
              ),
              RaisedButton(
                child: Text('Client'),
                onPressed: wifiExample.clientExample,
              ),
              RaisedButton(
                child: Text('Send message'),
                onPressed: wifiExample.sendMessageExample,
              ),
              RaisedButton(
                child: Text('Read message'),
                onPressed: wifiExample.receiveMessageExample,
              ),
            ],
          ),
        ),
      ),
    );
  }
}