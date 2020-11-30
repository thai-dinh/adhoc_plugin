import 'dart:typed_data';

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
    BleMessageManager _msgManager = BleMessageManager(_bleManager);
    Header header = Header(0, 'hello', 'myPhone', 'myAddress');
    MessageAdHoc msg = MessageAdHoc(header, 'A message');

    _msgManager.sendMessage(msg);
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
                child: Text('Connect'),
                onPressed: _bleManager.connect,
              ),
              RaisedButton(
                child: Text('Send data'),
                onPressed: () => _bleManager.writeValue(Uint8List.fromList([1, 2, 3])),
              ),
              RaisedButton(
                child: Text('Read data'),
                onPressed: _bleManager.readValue,
              ),
              RaisedButton(
                child: Text('Send message'),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
