import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:adhoc_plugin/adhoc_plugin.dart';
import 'package:adhoc_plugin_example/search_bar.dart';
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
  static const PLAYLIST = 0;
  static const REQUEST = 0;
  static const REPLY = 0;

  final TransferManager _manager = TransferManager(true);
  final List<AdHocDevice> _discovered = List.empty(growable: true);
  final List<AdHocDevice> _peers = List.empty(growable: true);
  final HashMap<String, HashMap<String, PlatformFile>> _globalPlaylist = HashMap();
  final HashMap<String, PlatformFile> _localPlaylist = HashMap();

  bool _requested = false;
  bool _display = false;
  String _selected = 'None';

  @override
  void initState() {
    super.initState();
    _manager.discoveryStream.listen(_processDiscoveryEvent);
    _manager.eventStream.listen(_processAdHocEvent);
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
                      List<String> songs = List.empty(growable: true);
                      _localPlaylist.entries.map((entry) => songs.add(entry.key));

                      _selected = await showSearch(
                        context: context,
                        delegate: SearchBar(songs),
                      );

                      if (_selected == null)
                        _selected = 'None';
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
                    Card(child: ListTile(title: Center(child: Text('Ad Hoc Peers')))),
                    ElevatedButton(
                      child: Center(child: Text('Search for nearby devices')),
                      onPressed: () => _manager.discovery(),
                    ),
                    Expanded(
                      child: ListView(
                        children: _discovered.map((device) {
                          return Card(
                            child: ListTile(
                              title: Center(child: Text(device.name)),
                              subtitle: Center(child: Text('[${device.mac.ble}/${device.mac.wifi}')),
                              onTap: () async {
                                await _manager.connect(device);
                                setState(() => _discovered.removeWhere((element) => (element.mac == device.mac)));
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

  void _processDiscoveryEvent(DiscoveryEvent event) {
    if (event.type == DISCOVERY_END) {
      setState(() {
        (event.payload as Map).entries.forEach(
          (element) => _discovered.add(element.value)
        );
      });
    }
  }

  void _processAdHocEvent(AdHocEvent event) {
    switch (event.type) {
      case CONNECTION_EVENT:
        _processConnection(event.payload as AdHocDevice);
        break;

      case DATA_RECEIVED:
        _processDataReceived(event.payload as List);
        break;

      case FORWARD_DATA:
        _processDataReceived(event.payload as List);
        break;

      default:
    }
  }

  void _processConnection(AdHocDevice device) {
    _peers.add(device);
  }

  void _processDataReceived(List payload) {
    AdHocDevice peer = payload.first;
    Map data = payload.last;

    switch (data['type']) {
      case PLAYLIST:
        List<String> peers = data['peers'];
        List<String> songs = data['songs'];
        String peerName = peers.first;
        HashMap<String, PlatformFile> entry = _globalPlaylist[peerName];
        if (entry == null)
          entry = HashMap();

        for (int i = 0; i < peers.length; i++) {
          if (peerName == peers[i]) {
            entry.putIfAbsent(songs[i], () => null);
          } else {
            _globalPlaylist[peerName] = entry;

            peerName = peers[i];
            entry = _globalPlaylist[peerName];
            if (entry == null)
              entry = HashMap();
            entry.putIfAbsent(songs[i], () => null);
          }
        }

        _globalPlaylist[peerName] = entry;
        break;

      case REQUEST:
        Uint8List bytes = _localPlaylist[data['name']].bytes;
        HashMap<String, dynamic> message = HashMap();
        message.putIfAbsent('type', () => REPLY);
        message.putIfAbsent('name', () => data['name']);
        message.putIfAbsent('song', () => bytes);
        _manager.sendMessageTo(message, peer.label);
        break;

      case REPLY:
        _processReply(peer, data);
        break;

      default:
    }
  }

  void _processReply(AdHocDevice peer, Map data) async {
    String name = data['name'];
    Uint8List song = Uint8List.fromList((data['song'] as List<dynamic>).cast<int>());

    Directory tempDir = await getTemporaryDirectory();
    File tempFile = File('${tempDir.path}/$name');
    await tempFile.writeAsBytes(song, flush: true);

    HashMap<String, PlatformFile> entry = HashMap();
    entry.putIfAbsent(
      name, () => PlatformFile(bytes: song, name: name, path: tempFile.path)
    );

    _globalPlaylist.putIfAbsent(peer.label, () => entry);
    setState(() => _requested = false);
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
    }

    _updatePlaylist();
  }

  void _updatePlaylist() async {
    List<String> peers = List.empty(growable: true);
    List<String> songs = List.empty(growable: true);

    Map<int, String> deviceNames = await _manager.getActifAdapterNames();
    String deviceName = 
      deviceNames[BLE] == null ? deviceNames[WIFI] : deviceNames[BLE];

    _globalPlaylist.forEach((peer, song) {
      peers.add(peer);
      song.forEach((key, value) {
        songs.add(key);
      });
    });

    _localPlaylist.forEach((name, file) {
      peers.add(deviceName);
      songs.add(name);
    });

    HashMap<String, dynamic> message = HashMap();
    message.putIfAbsent('type', () => PLAYLIST);
    message.putIfAbsent('peers', () => peers);
    message.putIfAbsent('songs', () => songs);
    _manager.broadcast(message);
  }
}
