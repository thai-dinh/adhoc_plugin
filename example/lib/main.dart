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
  BleClientExample bleExample = BleClientExample();
  WifiClientExample wifiExample = WifiClientExample();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  RaisedButton(
                    child: Text('Start advertise'),
                    onPressed: bleExample.startAdvertiseExample,
                  ),
                  RaisedButton(
                    child: Text('Stop advertise'),
                    onPressed: bleExample.stopAdvertiseExample,
                  ),
                  RaisedButton(
                    child: Text('Start scan'),
                    onPressed: bleExample.startScanExample,
                  ),
                  RaisedButton(
                    child: Text('Stop scan'),
                    onPressed: bleExample.stopScanExample,
                  ),
                  RaisedButton(
                    child: Text('Connect'),
                    onPressed: bleExample.connectExample,
                  ),
                  RaisedButton(
                    child: Text('Send'),
                    onPressed: bleExample.sendMessageExample,
                  ),
                  RaisedButton(
                    child: Text('Receive'),
                    onPressed: bleExample.receiveMessageExample,
                  ),
                ],
              ),

              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  RaisedButton(
                    child: Text('Register'),
                    onPressed: wifiExample.registerExample,
                  ),
                  RaisedButton(
                    child: Text('Unregister'),
                    onPressed: wifiExample.unregisterExample,
                  ),
                  RaisedButton(
                    child: Text('Discovery'),
                    onPressed: wifiExample.discoveryExample,
                  ),
                  RaisedButton(
                    child: Text('Connect'),
                    onPressed: wifiExample.connectExample,
                  ),
                  RaisedButton(
                    child: Text('Cancel connection'),
                    onPressed: wifiExample.cancelConnectionExample,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}