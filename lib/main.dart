import 'dart:collection';

import 'package:AdHocLibrary/datalink/bluetooth/bt_adhoc_device.dart';
import 'package:AdHocLibrary/datalink/bluetooth/bt_adhoc_manager.dart';
import 'package:AdHocLibrary/datalink/wifi/wifi_adhoc_manager.dart';

import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ad Hoc Library',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Ad Hoc Library Dev'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  BluetoothAdHocManager bt = BluetoothAdHocManager();
  WifiAdHocManager wifi = WifiAdHocManager();

  HashMap<String, BluetoothAdHocDevice> devices;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            RaisedButton(
              child: Text('Enable WiFi'),
              onPressed: wifi.enable,
            ),
            RaisedButton(
              child: Text('Disable WiFi'),
              onPressed: wifi.disable,
            ),
            RaisedButton(
              child: Text('Enable BT'),
              onPressed: bt.enable,
            ),
            RaisedButton(
              child: Text('Disable BT'),
              onPressed: bt.disable,
            ),
            RaisedButton(
              child: Text('EnableDiscovery'),
              onPressed: () => bt.enableDiscovery(300),
            ),
            RaisedButton(
              child: Text('Discovery'),
              onPressed: bt.discovery,
            ),
            RaisedButton(
              child: Text('PairedDevices'),
              onPressed: () => bt.getPairedDevices().then((value) => devices = value),
            ),
            RaisedButton(
              child: Text('UnpairDevice'),
              onPressed: () => {
                devices.forEach((key, value) {
                  if (value.deviceName == 'Device A')
                    bt.unpairDevice(key);
                })
              }
            ),
          ],
        ),
      ),
    );
  }
}
