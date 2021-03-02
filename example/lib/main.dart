import 'dart:collection';
import 'dart:math';

import 'package:adhoclibrary/adhoclibrary.dart' hide WifiAdHocDevice;
import 'package:adhoclibrary_example/aodv_plugin.dart';
import 'package:flutter/material.dart';
import 'datalink/wifi/wifi_adhoc_device.dart';

void main() {
  runApp(ExampleApp());
}

class ExampleApp extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<ExampleApp> {
  static const NAMES = ['Device A', 'Device B', 'Device C'];
  static const NB_DEVICES = 3;

  HashMap<String, AodvPlugin> _plugins = HashMap();
  List<AdHocDevice> _adhocdevices = List.empty(growable: true); 

  String _randomMac(){
    List<String> list = [
      '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'
    ];
    Random rand = Random(DateTime.now().millisecond);
    StringBuffer buffer = StringBuffer();

    for (int i = 0; i < 12; i++) {
      if (i % 2 == 0 && i != 0)
        buffer.write(':');
      buffer.write(list[rand.nextInt(list.length)]);
    }

    return buffer.toString();
  }

  void _initialize() {
    for (int i = 0; i < NB_DEVICES; i++) {
      int port = Random().nextInt(9999);
      while (port < 1000)
        port = Random().nextInt(9999);
      _adhocdevices.add(WifiAdHocDevice.unit(NAMES[i], _randomMac(), port));
    }

    for (int i = 0; i < NB_DEVICES; i++)
      _plugins.putIfAbsent(NAMES[i], () => AodvPlugin(i, _adhocdevices));
  }

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController _dstCtrl = TextEditingController();
    TextEditingController _msgCtrl = TextEditingController();
    MessageAdHoc _msg;
    int _destID;

    return MaterialApp(
      home: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            bottom: TabBar(
              tabs: [
                Tab(child: Center(child: Text('Device A'))),
                Tab(child: Center(child: Text('Device B'))),
                Tab(child: Center(child: Text('Device C'))),
              ],
            ),
            title: Text('Tabs Demo'),
          ),
          body: TabBarView(
            children: [
              Column(
                children: <Widget>[
                  Expanded(
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            children: <Widget>[
                              RaisedButton(
                                child: Center(child: Text('Connect')),
                                onPressed: () => _plugins[NAMES[1]].connectOnce(_adhocdevices[0])
                              ),
                              RaisedButton(
                                child: Center(child: Text('Disconnect')),
                                onPressed: () {  },
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text('Name: ${NAMES[1]}'),
                              Text('MAC: ${_adhocdevices[1].mac}'),
                              Text('ID: ${_adhocdevices[1].label}'),
                              Text('Port: ${(_adhocdevices[1] as WifiAdHocDevice).port}'),
                              Text('IP: ${_adhocdevices[1].address}'),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: <Widget>[
                              Text('Routing table'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: <Widget>[

                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          children: <Widget>[
                            RaisedButton(
                              child: Center(child: Text('Send')),
                              onPressed: () => _plugins[NAMES[1]].sendMessageTo(_msg, _adhocdevices[_destID])
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: <Widget>[
                            TextFormField(
                              controller: _msgCtrl,
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(hintText: 'Message'),
                              onEditingComplete: () {
                                _msg = MessageAdHoc(
                                  Header(
                                    messageType: 0,
                                    label: _adhocdevices[1].label,
                                    name: NAMES[1],
                                    address: _adhocdevices[1].address,
                                    mac: _adhocdevices[1].mac,
                                    deviceType: Service.WIFI,
                                  ),
                                  _msgCtrl.text,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                        children: <Widget>[
                          TextFormField(
                            controller: _dstCtrl,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(hintText: 'Destination'),
                            onEditingComplete: () {
                              switch (_dstCtrl.text) {
                                case 'A':
                                  _destID = 0;
                                  break;
                                case 'C':
                                  _destID = 2;
                                  break;
                              }
                            },
                          ),
                        ],
                      ),
                      ),
                    ],
                  ),
                ],
              ),
              Icon(Icons.directions_transit),
              Icon(Icons.directions_bike),
            ],
          ),
        ),
      ),
    );
  }
}
