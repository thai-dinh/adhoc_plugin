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
            ],
          ),
        ),
      ),
    );
  }
}
