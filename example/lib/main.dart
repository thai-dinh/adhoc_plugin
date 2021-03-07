import 'dart:collection';

import 'package:adhoclibrary/adhoclibrary.dart';
import 'package:adhoclibrary_example/distributed_cache/music_search_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_document_picker/flutter_document_picker.dart';


void main() => runApp(AdHocMusicClient());

class AdHocMusicClient extends StatefulWidget {
  @override
  _AdHocMusicClientState createState() => _AdHocMusicClientState();
}

class _AdHocMusicClientState extends State<AdHocMusicClient> {
  static const _prefix = r'/data/user/0/com.montefiore.thaidinhle.adhoclibrary_example/cache/';
  static const _platform = const MethodChannel('adhoc.music.player/main');

  final TransferManager _manager = TransferManager(true);
  final HashMap<String, String> _mapNamePath = HashMap();
  final List<AdHocDevice> _devices = List.empty(growable: true);
  final List<String> _songNames = List.empty(growable: true);

  bool _connected = false;
  String _path;

/*-----------------------------Override methods------------------------------*/

  @override
  void initState() {
    super.initState();

    _manager.eventStream.listen((event) {
      print(event.toString());
    });

    _manager.discoveryStream.listen((event) {
      switch (event.type) {
        case Service.DISCOVERY_END:
          setState(() {
            (event.payload as Map).entries.forEach(
              (element) => _devices.add(element.value)
            );
          });
          break;

        default:
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: <String, WidgetBuilder> {
        '/search' : (BuildContext context) => MusicSearchEngine(['Test']),
      },
      home: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: const Text('Ad Hoc Music Client'),
            actions: <Widget>[
              IconButton(
                icon: Icon(Icons.add_circle),
                onPressed: () async {
                  _path = await FlutterDocumentPicker.openDocument();
                  _mapNamePath.putIfAbsent(_path.replaceAll(RegExp(_prefix), ''), () => _path);
                }
              ),
            ],
          ),
          body: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Expanded(
                child: Column(
                  children: <Widget>[
                    ElevatedButton(
                      child: Center(child: Text('Search for music')),
                      onPressed: () => Navigator.pushNamed(context, '/search'),
                    ),
                    ElevatedButton(
                      child: Center(child: Text('Search for nearby devices')),
                      onPressed: () => _manager.discovery(),
                    ),
                    Expanded(
                      child: ListView(
                        children: _devices.map((device) {
                          return Card(
                            child: ListTile(
                              title: Center(child: Text(device.name)),
                              subtitle: Center(child: Text(device.mac)),
                              onTap: () async {
                                await _manager.connect(device);
                                _connected = true;
                                setState(() {
                                  _devices.removeWhere(
                                    (element) => (element.mac == device.mac)
                                  );
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

/*------------------------------Private methods------------------------------*/

}
