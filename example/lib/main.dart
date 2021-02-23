import 'package:adhoclibrary/adhoclibrary.dart';
import 'package:adhoclibrary_example/datalink/ble_plugin.dart';
import 'package:adhoclibrary_example/datalink/wifi_plugin.dart';

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
  WifiPlugin _wifiPlugin = WifiPlugin();
  BlePlugin _blePlugin = BlePlugin();
  List<AdHocDevice> _devices = [];
  bool _type = false;

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
                  RaisedButton(
                    child: Center(child: Text('Swap type')),
                    onPressed: () => setState(() {
                      _type = !_type;
                    }),
                  ),
                  if (_type) ...<Widget>[
                    Center(child: Text('Wifi P2P Display')),
                    RaisedButton(
                      child: Center(child: Text('Refresh')),
                      onPressed: () => setState(() {
                        _devices = _wifiPlugin.discoveredDevices;
                      }),
                    ),
                    RaisedButton(
                      child: Center(child: Text('Discovery')),
                      onPressed: () => _wifiPlugin.discovery(),
                    ),
                    RaisedButton(
                      child: Center(child: Text('disconnectAll')),
                      onPressed: () => _wifiPlugin.disconnectAll(),
                    ),
                    RaisedButton(
                      child: Center(child: Text('removeGroup')),
                      onPressed: () => _wifiPlugin.removeGroup(),
                    ),
                    RaisedButton(
                      child: Center(child: Text('printAdapterName')),
                      onPressed: () => _wifiPlugin.printAdapterName(),
                    ),
                    RaisedButton(
                      child: Center(child: Text('unregister')),
                      onPressed: () => _wifiPlugin.unregister(),
                    ),
                    ListView(
                      shrinkWrap: true,
                      physics: ClampingScrollPhysics(),
                      children: _devices.map((device) {
                        return Card(
                          child: ListTile(
                            title: Center(child: Text(device.name)),
                            subtitle: Center(child: Text(device.mac)),
                            onTap: () => _wifiPlugin.connect(device),
                          ),
                        );
                      }).toList(),
                    ),
                  ] else ...<Widget>[
                    Center(child: Text('Bluetooth Low Energy Display')),
                    RaisedButton(
                      child: Center(child: Text('Refresh')),
                      onPressed: () => setState(() {
                        _devices = _blePlugin.discoveredDevices;
                      }),
                    ),
                    RaisedButton(
                      child: Center(child: Text('enable')),
                      onPressed: () => _blePlugin.enable(),
                    ),
                    RaisedButton(
                      child: Center(child: Text('disable')),
                      onPressed: () => _blePlugin.disable(),
                    ),
                    RaisedButton(
                      child: Center(child: Text('Discovery')),
                      onPressed: () => _blePlugin.discovery(),
                    ),
                    RaisedButton(
                      child: Center(child: Text('stopListening')),
                      onPressed: () => _blePlugin.stopListening(),
                    ),
                    RaisedButton(
                      child: Center(child: Text('getAdapterName')),
                      onPressed: () => _blePlugin.getAdapterName(),
                    ),
                    RaisedButton(
                      child: Center(child: Text('updateDeviceName')),
                      onPressed: () => _blePlugin.updateDeviceName(),
                    ),
                    RaisedButton(
                      child: Center(child: Text('disconnectAll')),
                      onPressed: () => _blePlugin.disconnectAll(),
                    ),
                    ListView(
                      shrinkWrap: true,
                      physics: ClampingScrollPhysics(),
                      children: _devices.map((device) {
                        return Card(
                          child: ListTile(
                            title: Center(child: Text(device.name)),
                            subtitle: Center(child: Text(device.mac)),
                            onTap: () => _blePlugin.connect(device),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
