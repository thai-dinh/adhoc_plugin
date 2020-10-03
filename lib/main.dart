import 'package:AdHocLibrary/src/datalink/bluetooth/bt_adhoc_manager.dart';
import 'package:AdHocLibrary/src/datalink/bluetooth/bt_util.dart';

import 'package:flutter/material.dart';

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
  String _macAddress = "Unknown";

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    String mac = await new BluetoothUtil().getCurrentMac();

    setState(() {
      _macAddress = mac;
    });
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
              child: Text('Discovery'),
              onPressed: () => bt.enableDiscovery(300),
            ),
            RaisedButton(
              child: Text('ResetName'),
              onPressed: bt.resetDeviceName,
            ),
            RaisedButton(
              child: Text('UpdateName'),
              onPressed: () => bt.updateDeviceName('Galaxy A6 TD-OP'),
            ),
            RaisedButton(
              child: Text('Discovery'),
              onPressed: bt.discovery,
            ),
            RaisedButton(onPressed: initPlatformState),
            Text('MAC Address : $_macAddress\n'),
          ],
        ),
      ),
    );
  }
}
