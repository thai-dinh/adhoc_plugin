import 'dart:collection';
import 'dart:io';

import 'package:adhoclibrary/adhoclibrary.dart';
import 'package:analyzer_plugin/utilities/pair.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';


void main() => runApp(AdHocMusicClient());

enum MenuOptions { add, search, display }

const platform = const MethodChannel('adhoc.music.player/main');

class AdHocMusicClient extends StatefulWidget {
  @override
  _AdHocMusicClientState createState() => _AdHocMusicClientState();
}

class _AdHocMusicClientState extends State<AdHocMusicClient> {
  static const _PLAYLIST = 0;
  static const _REQUEST = 1;
  static const _REPLY = 2;

  final TransferManager _manager = TransferManager(true);
  final HashMap<AdHocDevice, HashMap<String, PlatformFile>> _peersPlaylist = HashMap();
  final HashMap<String, PlatformFile> _localPlaylist = HashMap();
  final List<AdHocDevice> _discoveredDevices = List.empty(growable: true);
  final List<Pair<String, String>> _playlist  = List.empty(growable: true);

  bool _display = false;
  bool _requested = false;
  String _selected = 'None';

  @override
  void initState() {
    super.initState();

    _manager.eventStream.listen((event) async {
      if (event.type == AbstractWrapper.DATA_RECEIVED) {
        AdHocDevice peer = event.payload as AdHocDevice;
        Map<String, dynamic> data = event.extra as Map;
        switch (data['type']) {
          case _PLAYLIST:
            HashMap<String, PlatformFile> payload = HashMap();
            setState(() => (data['playlist'] as List).forEach((name) {
              payload.putIfAbsent(name, () => null);
              _playlist.add(Pair(peer.name, name));
              _peersPlaylist.update(
                peer, (value) => data['playlist'], ifAbsent: () => payload
              );
            }));
            break;

          case _REQUEST:
            HashMap<String, dynamic> message = HashMap();
            message.putIfAbsent('type', () => _REPLY);
            message.putIfAbsent('name', () => data['name']);
            message.putIfAbsent('song', () => _localPlaylist[data['name']].bytes);
            _manager.sendMessageTo(message, peer);
            break;

          case _REPLY:
            String name = data['name'];
            Directory tempDir = await getTemporaryDirectory();
            File tempFile = File('${tempDir.path}/$name');
            await tempFile.writeAsBytes(data['song'], flush: true);

            _peersPlaylist.update(peer, (value) {
              value.putIfAbsent(
                data['name'], 
                () => PlatformFile(bytes: data['song'], name: data['name'], path: tempFile.path)
              );
              return value;
            });
            setState(() => _requested = false);
            break;

          default:
        }
      }
    });

    _manager.discoveryStream.listen((event) {
      if (event.type == Service.DISCOVERY_END) {
        setState(() {
          (event.payload as Map).entries.forEach(
            (element) => _discoveredDevices.add(element.value)
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: const Text('Ad Hoc Music Client'),
            actions: <Widget>[
              PopupMenuButton<MenuOptions>(
                onSelected: (MenuOptions result) async {
                  switch (result) {
                    case MenuOptions.add:
                      await _openFileExplorer();
                      setState(() { 
                        _localPlaylist.forEach(
                          (name, song) {
                            Pair pair = Pair('local', name);
                            if (!_playlist.contains(pair))
                              _playlist.add(Pair('local', name)); 
                          }
                        );
                      });
                      break;

                    case MenuOptions.search:
                      setState(() async { 
                        _selected = await showSearch(
                          context: context,
                          delegate: SearchBar(_localPlaylist),
                        );

                        if (_selected == null)
                          _selected = 'None';
                      });
                      break;

                    case MenuOptions.display:
                      setState(() => _display = !_display);
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<MenuOptions>>[
                  const PopupMenuItem<MenuOptions>(
                    value: MenuOptions.add,
                    child: ListTile(
                      leading: const Icon(Icons.playlist_add),
                      title: const Text('Add song to playlist'),
                    ),
                  ),
                  const PopupMenuItem<MenuOptions>(
                    value: MenuOptions.search,
                    child: ListTile(
                      leading: const Icon(Icons.search),
                      title: const Text('Search song'),
                    ),
                  ),
                  const PopupMenuItem<MenuOptions>(
                    value: MenuOptions.display,
                    child: ListTile(
                      leading: const Icon(Icons.music_note),
                      title: const Text('Switch view'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Expanded(
                child: Column(
                  children: <Widget>[
                    if (!_display) ...<Widget>[
                      Card(
                        child: ListTile(
                          title: Center(child: Text('Ad Hoc Peers')),
                        ),
                      ),
                      ElevatedButton(
                        child: Center(child: Text('Search for nearby devices')),
                        onPressed: () => _manager.discovery(),
                      ),
                      Expanded(
                        child: ListView(
                          children: _discoveredDevices.map((device) {
                            return Card(
                              child: ListTile(
                                title: Center(child: Text(device.name)),
                                subtitle: Center(child: Text(device.mac)),
                                onTap: () async {
                                  await _manager.connect(device);

                                  List<String> payload = List.empty(growable: true);
                                  _localPlaylist.forEach((name, file) => payload.add(name));

                                  HashMap<String, dynamic> message = HashMap();
                                  message.putIfAbsent('type', () => _PLAYLIST);
                                  message.putIfAbsent('playlist', () => payload);
                                  _manager.broadcast(message);

                                  Future.delayed(Duration(seconds: 2), () => _manager.broadcast(message));
                                  setState(() {
                                    _discoveredDevices.removeWhere(
                                      (element) => (element.mac == device.mac)
                                    );
                                  });
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ] else ...<Widget>[
                      Card(
                        child: Stack(
                          children: <Widget> [
                            ListTile(
                              title: Center(child: Text('$_selected')),
                              subtitle: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  IconButton(
                                    icon: Icon(Icons.play_arrow_rounded),
                                    onPressed: () {
                                      if (_selected == 'None')
                                        return;

                                      AdHocDevice dest;
                                      PlatformFile song;
                                      String peerName = _playlist.where((pair) => pair.last == _selected).first.first;
                                      if (peerName.compareTo('local') == 0) {
                                        song = _localPlaylist[_selected];
                                      } else {
                                        _peersPlaylist.forEach((peer, playlist) { 
                                          if (peer.name.compareTo(peerName) == 0)
                                            dest = peer;
                                        });

                                        song = _peersPlaylist[dest][_selected];
                                      }

                                      if (song == null) {
                                        HashMap<String, dynamic> message = HashMap();
                                        message.putIfAbsent('type', () => _REQUEST);
                                        message.putIfAbsent('name', () => _selected);
                                        _manager.sendMessageTo(message, dest);
                                        setState(() => _requested = true);
                                      } else {
                                        platform.invokeMethod('play', song.path);
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.pause_rounded),
                                    onPressed: () {
                                      if (_selected.compareTo('None') == 0)
                                        return;
                                      platform.invokeMethod('pause');
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.stop_rounded),
                                    onPressed: () {
                                      if (_selected.compareTo('None') == 0)
                                        return;
                                      _selected = 'None';
                                      platform.invokeMethod('stop');
                                    },
                                  ),
                                  if (_requested)
                                    Container(
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    )
                                  else
                                    Container(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Card(
                        color: Colors.blue,
                        child: ListTile(
                          title: Center(
                            child: const Text(
                              'Ad Hoc Playlist',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          children: _playlist.map((pair) {
                            String peerName = pair.first;
                            String songName = pair.last;
                            return Card(
                              child: ListTile(
                                title: Center(child: Text(songName)),
                                subtitle: Center(child: Text(peerName)),
                                onTap: () => setState(() => _selected = songName),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openFileExplorer() async {
    FilePickerResult result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.audio,
    );

    if(result != null) {
      for (PlatformFile file in result.files) {
        PlatformFile song = PlatformFile(
          name: file.name,
          path: file.path,
          bytes: await File(file.path).readAsBytes(),
        );

        print(song.bytes.length);
        _localPlaylist.putIfAbsent(file.name, () => song);
      }

      List<String> payload = List.empty(growable: true);
      _localPlaylist.forEach((name, file) => payload.add(name));

      HashMap<String, dynamic> message = HashMap();
      message.putIfAbsent('type', () => _PLAYLIST);
      message.putIfAbsent('playlist', () => payload);
      _manager.broadcast(message);
    }
  }
}

class SearchBar extends SearchDelegate<String> {
  final HashMap<String, PlatformFile> _playlist;

  List<String> _recentPick;
  String _selected = '';

  SearchBar(this._playlist) {
    this._recentPick = List.empty(growable: true);
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return <Widget>[
      IconButton(
        icon: Icon(Icons.close),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back), 
      onPressed: () => Navigator.pop(context),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    this.close(context, _selected);
    return null;
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    List<String> suggestions = List.empty(growable: true);

    if (query.isEmpty) {
      suggestions = _recentPick;
    } else {
      List<String> songNames = List.empty(growable: true);
      _playlist.forEach((key, value) => songNames.add(key));
      suggestions.addAll(songNames.where((element) => element.contains(query)));
    }

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (BuildContext context, int index) {
        return ListTile(
          title: Text(suggestions[index]),
          onTap: () {
            _selected = suggestions[index];
            showResults(context);
          },
        );
      }
    );
  }
}