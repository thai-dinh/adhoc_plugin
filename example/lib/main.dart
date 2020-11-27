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
  BluetoothLowEnergyDevice _device = BluetoothLowEnergyDevice();

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
                onPressed: _device.startAdvertise,
              ),
              RaisedButton(
                child: Text('Stop advertising'),
                onPressed: _device.stopAdvertise,
              ),
              RaisedButton(
                child: Text('Start scan'),
                onPressed: _device.startScan,
              ),
              RaisedButton(
                child: Text('Stop scan'),
                onPressed: _device.stopScan,
              ),
              RaisedButton(
                child: Text('Connect'),
                onPressed: _device.connect,
              ),
              RaisedButton(
                child: Text('Send data'),
                onPressed: () => _device.writeValue(Uint8List.fromList([1, 2, 3])),
              ),
              RaisedButton(
                child: Text('Read data'),
                onPressed: _device.readValue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
