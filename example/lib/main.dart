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
  Central _central = Central();
  Peripheral _peripheral = Peripheral();

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
                onPressed: _peripheral.startAdvertise,
              ),
              RaisedButton(
                child: Text('Stop advertising'),
                onPressed: _peripheral.stopAdvertise,
              ),
              RaisedButton(
                child: Text('Start scan'),
                onPressed: _central.startScan,
              ),
              RaisedButton(
                child: Text('Stop scan'),
                onPressed: _central.stopScan,
              ),
              RaisedButton(
                child: Text('Connect'),
                onPressed: _central.connect,
              ),
              RaisedButton(
                child: Text('Discover services'),
                onPressed: _central.discoverServices,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
