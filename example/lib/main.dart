import 'dart:collection';
import 'dart:typed_data';

import 'package:adhoc_plugin/adhoc_plugin.dart';
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
  static const PLAYLIST = 0;
  static const REQUEST = 0;
  static const REPLY = 0;

  final TransferManager _manager = TransferManager(true);
  final List<AdHocDevice> _discovered = List.empty(growable: true);
  final List<AdHocDevice> _peers = List.empty(growable: true);
  final HashMap<String, PlatformFile> _globalPlaylist = HashMap();
  final HashMap<String, PlatformFile> _localPlaylist = HashMap();

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
                      break;
                    case MenuOptions.search:
                      break;
                    case MenuOptions.display:
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
        
        break;

      default:
    }
  }
}
