import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:adhoc_plugin/adhoc_plugin.dart';
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
  static const _PEERS = 3;

  final TransferManager _manager = TransferManager(true);
  final HashMap<AdHocDevice, HashMap<String, PlatformFile>> _peersPlaylist = HashMap();
  final HashMap<String, AdHocDevice> _peers = HashMap();
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
        List<dynamic> payload = event.payload;
        AdHocDevice peer = payload[0];
        Map<String, dynamic> data = payload[1];
        switch (data['type']) {
          case _PLAYLIST:
            HashMap<String, PlatformFile> received;
            HashSet<AdHocDevice> setDevices = _manager.setRemoteDevices;
            List<Pair<String, String>> list = List.empty(growable: true);
            List<String> peerNames = (data['peerNames'] as List).cast<String>();
            List<String> songNames = (data['songNames'] as List).cast<String>();
            String name = '';

            for (int i = 0; i < peerNames.length; i++) {
              String _peerName = peerNames[i];
              if (_peerName.compareTo('local') == 0)
                _peerName = peer.name;
              list.add(Pair(_peerName, songNames[i]));
            }

            while (list.length > 0) {
              name = list.first.first;

              received = HashMap();
              Iterable<Pair<String, String>> it = list.where((element) => element.first == name);
              it.forEach((element) => received.putIfAbsent(element.last, () => null));

              Iterable<AdHocDevice> itAd = setDevices.where((element) => element.name == name);
              _peersPlaylist.update(
                itAd.isEmpty ? (_peers.containsKey(name) ? _peers[name] : peer) : itAd.first,
                (value) {
                  value.addAll(received);
                  return value;
                },
                ifAbsent: () => received
              );
              list.removeWhere((element) => element.first == name);
            }

            setState(() {
              _peersPlaylist.forEach(
                (peer, map) {
                  map.forEach((name, file) {
                    Pair<String, String> pair = Pair(peer.name, name);
                    if (!_playlist.contains(pair))
                      _playlist.add(pair); 
                  });
                }
              );
            });

            _updatePlaylist(peer: peer, except: true);
            break;

          case _REQUEST:
            Uint8List bytes = _localPlaylist[data['name']].bytes;
            HashMap<String, dynamic> message = HashMap();
            message.putIfAbsent('type', () => _REPLY);
            message.putIfAbsent('name', () => data['name']);
            message.putIfAbsent('song', () => bytes);
            _manager.sendMessageTo(message, peer);
            break;

          case _REPLY:
            String name = data['name'];
            List<int> song = (data['song'] as List<dynamic>).cast<int>();

            Directory tempDir = await getTemporaryDirectory();
            File tempFile = File('${tempDir.path}/$name');
            await tempFile.writeAsBytes(Uint8List.fromList(song), flush: true);

            HashMap<String, PlatformFile> payload = HashMap();
            payload.putIfAbsent(
              name, 
              () => PlatformFile(bytes: Uint8List.fromList(song), name: name, path: tempFile.path)
            );

            _peersPlaylist.update(peer,
              (value) {
                value.update(
                  name,
                  (value) => PlatformFile(bytes: Uint8List.fromList(song), name: name, path: tempFile.path)
                );
                return value;
              },
              ifAbsent: () => payload,
            );

            setState(() => _requested = false);
            break;

          case _PEERS:
            List<String> peerNames = (data['peerNames'] as List<dynamic>).cast<String>();
            List<String> peerLabels = (data['peerLabels'] as List<dynamic>).cast<String>();
            for (int i = 0; i < peerNames.length; i++)
              _peers.putIfAbsent(
                peerNames[i], 
                () => AdHocDevice(
                  label: peerLabels[i],
                  name: peerNames[i],
                )
              );
            break;

          default:
        }
      } else if (event.type == AbstractWrapper.CONNECTION_EVENT) {
        AdHocDevice peer = event.payload as AdHocDevice;
        _peers.putIfAbsent(peer.name, () => peer);
        _updatePlaylist(peer: peer);

        List<String> peerNames = List.empty(growable: true);
        List<String> peerLabels = List.empty(growable: true);
        _peers.forEach((name, peer) {
          peerNames.add(name);
          peerLabels.add(peer.label);
        });
        HashMap<String, dynamic> message = HashMap();
        message.putIfAbsent('type', () => _PEERS);
        message.putIfAbsent('peerNames', () => peerNames);
        message.putIfAbsent('peerLabels', () => peerLabels);
        _manager.sendMessageTo(message, peer);
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
                                subtitle: Center(child: Text(device.mac.ble + '/' + device.mac.wifi)),
                                onTap: () async {
                                  await _manager.connect(device);
                                  Future.delayed(Duration(seconds: 2), () => _updatePlaylist());
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
                                        bool found = false;
                                        _peersPlaylist.forEach((peer, playlist) { 
                                          if (peer.name.compareTo(peerName) == 0 && found == false) {
                                            dest = peer;
                                            if (_peersPlaylist[dest][_selected] != null)
                                              found = true;
                                          }
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

  Future<bool> _updatePlaylist({AdHocDevice peer, bool except}) async {
    List<String> peerNames = List.empty(growable: true);
    List<String> songNames = List.empty(growable: true);
    _playlist.forEach((element) {
      peerNames.add(element.first);
      songNames.add(element.last);
    });

    HashMap<String, dynamic> message = HashMap();
    message.putIfAbsent('type', () => _PLAYLIST);
    message.putIfAbsent('peerNames', () => peerNames);
    message.putIfAbsent('songNames', () => songNames);
    if (peer == null) {
      return _manager.broadcast(message);
    } else if (except != null && except) {
      return _manager.broadcastExcept(message, peer);
    } else {
      _manager.sendMessageTo(message, peer);
      return true;
    }
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

        _localPlaylist.putIfAbsent(file.name, () => song);
      }

      setState(() {
        _localPlaylist.forEach(
          (name, song) {
            Pair<String, String> pair = Pair('local', name);
            if (!_playlist.contains(pair))
              _playlist.add(pair);
          }
        );
      });

      _updatePlaylist();
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