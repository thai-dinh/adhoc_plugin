import 'package:adhoclibrary/adhoclibrary.dart';
import 'package:adhoclibrary_example/distributed_cache/music_search_engine.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/material.dart';

void main() => runApp(AdHocMusicClient());

class AdHocMusicClient extends StatefulWidget {
  @override
  _AdHocMusicClientState createState() => _AdHocMusicClientState();
}

class _AdHocMusicClientState extends State<AdHocMusicClient> {
  TransferManager _manager = TransferManager(true);
  List<AdHocDevice> _devices = List.empty(growable: true);

/*-----------------------------Override methods------------------------------*/

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
      debugShowCheckedModeBanner: false,
      routes: <String, WidgetBuilder> {
        '/search' : (BuildContext context) => MusicSearchEngine(['Test']),
      },
      home: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Center(child: Text('Ad Hoc Music Client'))),
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
                    ElevatedButton(
                      child: Center(child: Text('Search for nearby devices')),
                      onPressed: () {
                        AssetsAudioPlayer.newPlayer().open(
                          Audio("assets/audios/song1.mp3"),
                          autoStart: true,
                          showNotification: true,
                        );
                      },
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
      ),
    );
  }

/*------------------------------Private methods------------------------------*/

}
