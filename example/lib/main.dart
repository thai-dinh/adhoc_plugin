import 'dart:collection';
import 'dart:math';

import 'package:adhoclibrary/adhoclibrary.dart' hide WifiAdHocDevice;
import 'package:adhoclibrary_example/aodv_plugin.dart';
import 'package:adhoclibrary_example/datalink/wifi/wifi_adhoc_device.dart';
import 'package:flutter/material.dart';


void main() {
  runApp(ExampleApp());
}

class ExampleApp extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<ExampleApp> {
  static const NAMES = ['Device A', 'Device B', 'Device C', 'Device D'];
  static const NB_DEVICES = 4;

  HashMap<String, AodvPlugin> _plugins = HashMap();
  List<AdHocDevice> _adhocdevices = List.empty(growable: true);
  List<List<Widget>> logs = List.empty(growable: true);

  String _randomMac(){
    List<String> list = [
      '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'
    ];
    Random rand = Random();
    StringBuffer buffer = StringBuffer();

    for (int i = 0; i < 12; i++) {
      if (i % 2 == 0 && i != 0)
        buffer.write(':');
      buffer.write(list[rand.nextInt(list.length)]);
    }

    return buffer.toString();
  }

  void _initialize() {
    for (int i = 0; i < NB_DEVICES; i++)
      logs.add(List.empty(growable: true));

    for (int i = 0; i < NB_DEVICES; i++) {
      int port = Random(DateTime.now().microsecond).nextInt(9999);
      while (port < 1000)
        port = Random(DateTime.now().millisecond).nextInt(9999);
      String mac = _randomMac();
      _adhocdevices.add(WifiAdHocDevice.unit(NAMES[i], mac, port));
    }

    for (int i = 0; i < NB_DEVICES; i++) {
      _plugins.putIfAbsent(NAMES[i], () => AodvPlugin(i, _adhocdevices));
      _plugins[NAMES[i]].logs.listen((log) {
        setState(() {
          logs[i].add(Text(log));
        });
      });
    }
  }

  Widget _display(int index) {
    TextEditingController _dstCtrl = TextEditingController();
    TextEditingController _msgCtrl = TextEditingController();
    MessageAdHoc _msg;
    int _destID;
    return Column(
      children: <Widget>[
        Expanded(
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  children: <Widget>[
                    RaisedButton(
                      child: Center(child: Text('Connect')),
                      onPressed: () {
                        int j = index-1;
                        if (j < 0)
                          j = 0;
                        _plugins[NAMES[index]].connectOnce(_adhocdevices[j]);
                      }
                    ),
                    RaisedButton(
                      child: Center(child: Text('Disconnect')),
                      onPressed: () {
                        _plugins[NAMES[index]].disconnect(_adhocdevices[_destID].label);
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Name: ${NAMES[index]}'),
                    Text('MAC: ${_adhocdevices[index].mac}'),
                    Text('ID: ${_adhocdevices[index].label}'),
                    Text('Port: ${(_adhocdevices[index] as WifiAdHocDevice).port}'),
                    Text('IP: ${_adhocdevices[index].address}'),
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
        Expanded(
          child: Row(
            children: <Widget>[
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  physics: ClampingScrollPhysics(),
                  children: logs[index].map((widget) {
                    return Card(
                      child: ListTile(
                        title: Center(child: widget),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        Row(
          children: <Widget>[
            Expanded(
              child: Column(
                children: <Widget>[
                  RaisedButton(
                    child: Center(child: Text('Send')),
                    onPressed: () => _plugins[NAMES[index]].sendMessageTo(_msg, _adhocdevices[_destID])
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
                          label: _adhocdevices[index].label,
                          name: NAMES[index],
                          address: _adhocdevices[index].address,
                          mac: _adhocdevices[index].mac,
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
                      print(_dstCtrl.text);
                      switch (_dstCtrl.text) {
                        case 'A':
                          _destID = 0;
                          break;
                        case 'B':
                          _destID = 1;
                          break;
                        case 'C':
                          _destID = 2;
                          break;
                        case 'D':
                          _destID = 3;
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
    );
  }

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            bottom: TabBar(
              tabs: [
                Tab(child: Center(child: Text('Device A'))),
                Tab(child: Center(child: Text('Device B'))),
                Tab(child: Center(child: Text('Device C'))),
                Tab(child: Center(child: Text('Device D'))),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _display(0),
              _display(1),
              _display(2),
              _display(3),
            ],
          ),
        ),
      ),
    );
  }
}
