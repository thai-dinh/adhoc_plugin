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
  BleAdHocManager _bleManager = BleAdHocManager();

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
                child: Text('Start advertise'),
                onPressed: _bleManager.startAdvertise,
              ),
              RaisedButton(
                child: Text('Stop advertise'),
                onPressed: _bleManager.stopAdvertise,
              ),
              RaisedButton(
                child: Text('Start scan'),
                onPressed: _bleManager.startScan,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
