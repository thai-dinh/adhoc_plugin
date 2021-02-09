import 'package:adhoclibrary_example/ble_plugin.dart';
import 'package:adhoclibrary_example/wifi_plugin.dart';

import 'package:flutter/material.dart';

void main() {
  runApp(ExampleApp());
}

class ExampleApp extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<ExampleApp> {
  BlePlugin blePlugin = BlePlugin();
  WifiPlugin wifiPlugin = WifiPlugin();

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
                  Text(
                    'BluetoothLE'
                  ),
                  RaisedButton(
                    child: Text('Enable discovery'),
                    onPressed: blePlugin.enableExample,
                  ),
                  RaisedButton(
                    child: Text('Disable'),
                    onPressed: blePlugin.disableExample,
                  ),
                  RaisedButton(
                    child: Text('Discovery'),
                    onPressed: blePlugin.discoveryExample,
                  ),
                  RaisedButton(
                    child: Text('Connect'),
                    onPressed: blePlugin.connectExample,
                  ),
                  RaisedButton(
                    child: Text('Stop listening'),
                    onPressed: blePlugin.stopListeningExample,
                  ),
                  RaisedButton(
                    child: Text('Disconnect all'),
                    onPressed: blePlugin.disconnectAllExample,
                  ),
                ],
              ),

              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'Wifi P2P'
                  ),
                  RaisedButton(
                    child: Text('Enable discovery'),
                    onPressed: wifiPlugin.enableExample,
                  ),
                  RaisedButton(
                    child: Text('Disable'),
                    onPressed: wifiPlugin.disableExample,
                  ),
                  RaisedButton(
                    child: Text('Discovery'),
                    onPressed: wifiPlugin.discoveryExample,
                  ),
                  RaisedButton(
                    child: Text('Connect'),
                    onPressed: wifiPlugin.connectExample,
                  ),
                  RaisedButton(
                    child: Text('Stop listening'),
                    onPressed: wifiPlugin.stopListeningExample,
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
