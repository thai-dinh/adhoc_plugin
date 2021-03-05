import 'package:adhoclibrary/adhoclibrary.dart';
import 'package:adhoclibrary_example/distributed_cache/music_search_engine.dart';
import 'package:flutter/material.dart';

void main() => runApp(AdHocMusicClient());

class AdHocMusicClient extends StatefulWidget {
  @override
  _AdHocMusicClientState createState() => _AdHocMusicClientState();
}

class _AdHocMusicClientState extends State<AdHocMusicClient> {
  TransferManager _manager = TransferManager(true);
  List<AdHocDevice> _devices = List.empty(growable: true);

/*------------------------------Override methods------------------------------*/

  @override
  void initState() {
    super.initState();
    _manager.eventStream.listen((event) {

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
      routes: <String, WidgetBuilder> {
        '/search' : (BuildContext context) => MusicSearchEngine(),
      },
      home: Scaffold(
        appBar: AppBar(title: Center(child: Text('Ad Hoc Music Client'))),
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Expanded(
              child: Column(
                children: <Widget>[
                  ElevatedButton(
                    child: Center(child: Text('Search for music')),
                    onPressed: () => Navigator.of(context).pushNamed('/search'),
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
                            onTap: () {
                              _manager.connect(device);
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
    );
  }
}
