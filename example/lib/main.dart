import 'dart:collection';

import 'package:adhoclibrary/adhoclibrary.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


void main() => runApp(AdHocMusicClient());

enum MenuOptions { add, search, display }

const platform = const MethodChannel('adhoc.music.player/main');

class AdHocMusicClient extends StatefulWidget {
  @override
  _AdHocMusicClientState createState() => _AdHocMusicClientState();
}

class _AdHocMusicClientState extends State<AdHocMusicClient> {
  final TransferManager _manager = TransferManager(true);
  final HashMap<String, PlatformFile> _playlist = HashMap();
  final List<AdHocDevice> _devices = List.empty(growable: true);
  final List<String> _names = List.empty(growable: true);

  bool _display = false;

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
                      break;
                    case MenuOptions.search:
                      showSearch(context: context, delegate: SearchBar(_manager, _playlist));
                      break;
                    case MenuOptions.display:
                      _playlist.forEach((name, file) => _names.add(name));
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
                      title: const Text('Display playlist'),
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
                                  _manager.broadcast(_playlist);
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
                    ] else ...<Widget>[
                      Expanded(
                        child: ListView(
                          children: _names.map((name) {
                            return Card(
                              child: ListTile(
                                title: Center(child: Text(name)),
                                onTap: () async {
                                  // TODO: if file == null, fetch it from peers
                                  platform.invokeMethod('play', _playlist[name].path);
                                },
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
        String name = file.name;
        _playlist.putIfAbsent(name, () => file);
      }

      _manager.broadcast(_playlist);
    }
  }
}

class SearchBar extends SearchDelegate {
  final TransferManager _manager;
  final HashMap<String, PlatformFile> _playlist;

  List<String> _recentPick;
  String _selected = '';

  SearchBar(this._manager, this._playlist) {
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
    return Container(
      child: Center(
        child: IconButton(
          icon: Icon(Icons.play_arrow_rounded),
          onPressed: () {
            PlatformFile song = _playlist[_selected];
            if (song == null) {
              // TODO: request it from peer
            } else {
              platform.invokeMethod('play', song.path);
            }
          },
        ),
      ),
    );
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