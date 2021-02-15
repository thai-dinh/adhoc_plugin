import 'package:adhoclibrary/adhoclibrary.dart';
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
  List<AdHocDevice> discoveredDevice = [];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
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
              child: Text('Get discovered device'),
              onPressed: () {
                setState(() {
                  discoveredDevice = blePlugin.discoveredDevices;
                });
              },
            ),
            RaisedButton(
              child: Text('Stop listening'),
              onPressed: blePlugin.stopListeningExample,
            ),
            RaisedButton(
              child: Text('Disconnect all'),
              onPressed: blePlugin.disconnectAllExample,
            ),
            Expanded(
              child: ListView(
                children: discoveredDevice.map((device) {
                  return Card(
                    child: ListTile(
                      title: Center(child: Text(device.name)),
                      subtitle: Center(child: Text(device.mac)),
                      onTap: () {
                        print("Connect to device: ${device.mac}");
                        blePlugin.connectExample(device);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
