import 'package:adhoclibrary/adhoclibrary.dart';
import 'package:adhoclibrary_example/network/aodv_plugin.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(ExampleApp());
}

class ExampleApp extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<ExampleApp> {
  AodvPlugin _aodvPlugin = AodvPlugin();
  List<AdHocDevice> _devices = [];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Adhoclibrary plugin example'),
        ),
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Expanded(
              child: ListView(
                children: <Widget>[
                  RaisedButton(
                    child: Center(child: Text('Exit app')),
                    onPressed: () => SystemChannels.platform.invokeMethod('SystemNavigator.pop'),
                  ),
                  Center(child: Text('AODV Display')),
                  RaisedButton(
                    child: Center(child: Text('Refresh')),
                    onPressed: () => setState(() {
                      _devices = _aodvPlugin.discoveredDevices;
                    }),
                  ),
                  RaisedButton(
                    child: Center(child: Text('enable discovery')),
                    onPressed: () => _aodvPlugin.enableBluetooth(),
                  ),
                  RaisedButton(
                    child: Center(child: Text('discovery')),
                    onPressed: () => _aodvPlugin.discovery(),
                  ),
                  RaisedButton(
                    child: Center(child: Text('disconnectAll')),
                    onPressed: () => _aodvPlugin.disconnectAll(),
                  ),
                  ListView(
                    shrinkWrap: true,
                    physics: ClampingScrollPhysics(),
                    children: _devices.map((device) {
                      return Card(
                        child: ListTile(
                          title: Center(child: Text(device.name)),
                          subtitle: Center(child: Text(device.mac)),
                          onTap: () {
                            _aodvPlugin.connectOnce(device);
                            _aodvPlugin.sendMessageTo('Hello', device);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
