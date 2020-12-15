import 'package:adhoclibrary_example/ble_client_example.dart';

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
                child: Text('Open'),
                onPressed: example.openGattServer,
              ),
              RaisedButton(
                child: Text('Start advertise'),
                onPressed: example.startAdvertiseExample,
              ),
              RaisedButton(
                child: Text('Stop advertise'),
                onPressed: example.stopAdvertiseExample,
              ),
              RaisedButton(
                child: Text('Start scan'),
                onPressed: example.startScanExample,
              ),
              RaisedButton(
                child: Text('Stop scan'),
                onPressed: example.stopScanExample,
              ),
              RaisedButton(
                child: Text('Connect'),
                onPressed: example.connectExample,
              ),
              RaisedButton(
                child: Text('Send message'),
                onPressed: example.sendMessageExample,
              ),
              RaisedButton(
                child: Text('Read message'),
                onPressed: example.receiveMessageExample,
              ),
              RaisedButton(
                child: Text('Open Gatt Server'),
                onPressed: example.openGattServer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}