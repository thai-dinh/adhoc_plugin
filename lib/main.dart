import 'dart:async';

import 'package:AdHocLibrary/src/datalink/bluetooth/bt_adhoc_manager.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
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
  static const stream = const EventChannel('ad.hoc.library.dev/bluetooths.stream');
  StreamSubscription _subscription;

  void _listen() {
    _subscription = stream.receiveBroadcastStream().listen((event) { print(event); });
  }

  void _cancel() {
    _subscription.cancel();
  }

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
              child: Text('Enable'),
              onPressed: bt.enable,
            ),
            RaisedButton(
              child: Text('Disable'),
              onPressed: bt.disable,
            ),
            RaisedButton(
              child: Text('EnabelDiscovery'),
              onPressed: () => bt.enableDiscovery(300),
            ),
            RaisedButton(
              child: Text('Discovery'),
              onPressed: bt.discovery,
            ),
            RaisedButton(
              child: Text('PairedDevices'),
              onPressed: bt.getPairedDevices,
            ),
            RaisedButton(
              child: Text('Listen'),
              onPressed: _listen,
            ),
            RaisedButton(
              child: Text('Cancel'),
              onPressed: _cancel,
            ),
          ],
        ),
      ),
    );
  }
}
