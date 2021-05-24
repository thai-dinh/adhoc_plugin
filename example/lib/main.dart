import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:adhoc_plugin/adhoc_plugin.dart';
import 'package:adhoc_plugin_example/search_bar.dart';
import 'package:analyzer_plugin/utilities/pair.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';


void main() => runApp(AdHocMusicClient());

enum MenuOptions { add, search, display, group }

const platform = const MethodChannel('adhoc.music.player/main');

class AdHocMusicClient extends StatefulWidget {
  @override
  _AdHocMusicClientState createState() => _AdHocMusicClientState();
}

class _AdHocMusicClientState extends State<AdHocMusicClient> {
  static const PLAYLIST = 0;
  static const REQUEST = 1;
  static const REPLY = 2;

  static const NONE = 'none';
  static const LOCAL = 'local';

  final TransferManager _manager = TransferManager(true);
  final List<AdHocDevice> _discovered = List.empty(growable: true);
  final List<AdHocDevice> _peers = List.empty(growable: true);
  final HashMap<String, HashMap<String, PlatformFile>> _globalPlaylist = HashMap();
  final HashMap<String, PlatformFile> _localPlaylist = HashMap();
  final List<Pair<String, String>> _playlist = List.empty(growable: true);

  // bool _peerRequest = false;
  bool _requested = false;
  bool _display = false;
  String _selected = NONE;
  String _name = LOCAL;

  @override
  void initState() {
    super.initState();
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
                        _selected = NONE;
                      break;

                    case MenuOptions.display:
                      setState(() => _display = !_display);
                      break;

                    case MenuOptions.group:
                      _manager.createGroup(1);
                      Future.delayed(Duration(seconds: 17), () => _manager.sendMessageToGroup('Hello'));
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
                  const PopupMenuItem<MenuOptions>(
                    value: MenuOptions.group,
                    child: ListTile(
                      leading: const Icon(Icons.create),
                      title: const Text('Create a group'),
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
                                subtitle: Center(child: Text('${device.mac}')),
                                onTap: () async {
                                  await _manager.connect(device);
                                  setState(() => _discovered.removeWhere((element) => (element.mac == device.mac)));
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ] else ...<Widget>[
                      Card(child: Stack(
                        children: <Widget> [
                          ListTile(
                            title: Center(child: Text('$_selected')),
                            subtitle: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                IconButton(
                                  icon: Icon(Icons.play_arrow_rounded),
                                  onPressed: _play,
                                ),
                                IconButton(
                                  icon: Icon(Icons.pause_rounded),
                                  onPressed: _pause,
                                ),
                                IconButton(
                                  icon: Icon(Icons.stop_rounded),
                                  onPressed: _stop,
                                ),
                                if (_requested)
                                  Container(child: Center(child: CircularProgressIndicator()))
                                else
                                  Container()
                              ],
                            ),
                          ),
                        ],
                      )),

                      Card(
                        color: Colors.blue,
                        child: ListTile(
                          title: Center(
                            child: const Text('Ad Hoc Playlist', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ),

                      Card(
                        color: Colors.blue,
                        child: ListTile(
                          title: Center(
                            child: const Text('Broadcast lorem ipsum', style: TextStyle(color: Colors.white)),
                          ),
                          onTap: () {
                            String lorem_ipsum = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Proin fringilla non ligula dictum efficitur. Nam venenatis augue rhoncus odio fringilla viverra. In accumsan faucibus fermentum. Vivamus libero felis, posuere nec consectetur nec, molestie quis odio. Duis varius at magna eget pretium. Nunc suscipit augue at condimentum lobortis. Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Pellentesque enim justo, posuere nec dolor id, gravida rutrum urna. Suspendisse quis pellentesque augue, non pretium erat. Proin sit amet augue erat. Nunc ligula augue, suscipit ut leo ac, sagittis interdum arcu. Nunc maximus metus eu lorem iaculis mollis. Donec tortor purus, suscipit a dolor id, pretium mollis lacus. Maecenas magna tellus, vulputate id eros et, commodo condimentum elit. Donec elementum erat sed semper imperdiet. Sed erat mauris, tempus ut sollicitudin non, venenatis eget lorem. Quisque ullamcorper lacus turpis, et facilisis diam mollis vestibulum. Mauris sapien nisl, vehicula at vestibulum quis, egestas ut ligula. Quisque vitae felis risus. In lacinia risus quam. Duis ipsum lorem, pharetra in facilisis ut, fringilla a dolor. Sed aliquam posuere tellus, in facilisis ex. Aliquam dictum felis eros, ut facilisis leo sollicitudin at. Mauris pharetra fringilla magna, a lobortis mauris feugiat ac. Etiam varius sodales egestas. Nullam non augue mi. Aliquam vitae condimentum orci. In hac habitasse platea dictumst. Vestibulum purus libero, posuere eu metus at, fermentum posuere tortor. Mauris quis elit ipsum. Praesent vitae volutpat justo. Maecenas ac accumsan orci, vitae ultrices turpis. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Phasellus vitae tellus eget purus gravida consectetur. Aliquam iaculis velit eros. Curabitur vel suscipit velit, a facilisis augue. Ut consequat dignissim nunc, a maximus lectus lobortis sed. Donec scelerisque pellentesque finibus. Donec non neque quis velit placerat consectetur eget vitae massa. Duis volutpat nibh nec leo lacinia, id cursus elit porttitor. Sed varius, urna vel dignissim ultricies, mi sapien sagittis turpis, quis venenatis ligula augue sit amet augue. Quisque sollicitudin odio justo, nec ornare leo ornare id. Pellentesque auctor, odio id auctor posuere, sapien nisi dignissim nunc, ut scelerisque sem erat ut lorem. Fusce sodales erat quis nulla tempus condimentum. Nulla bibendum, sapien in interdum vehicula, nisi dui placerat odio, a molestie eros magna in lacus. Donec semper nulla et ligula sagittis, posuere dapibus leo pharetra. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Mauris lorem risus, tempus quis malesuada auctor, convallis aliquam metus. Duis non facilisis lacus. Quisque tempor finibus scelerisque. Mauris nisl enim, egestas ut hendrerit ut, varius eu mi. Sed sed enim ligula. Praesent imperdiet at dui vel pulvinar. Fusce pulvinar maximus libero mattis interdum. Nulla vel erat nunc. Vivamus accumsan metus elit, at bibendum massa eleifend non. Donec vel varius mi, eu laoreet neque. Sed iaculis purus ac mauris dapibus, id egestas orci mattis. Donec nec lorem justo. Maecenas fermentum maximus auctor. Cras sit amet mattis nisl. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Integer quis iaculis augue, in maximus est. Cras commodo sit amet lectus sit amet consectetur. Aliquam erat volutpat. Nunc sodales ligula eu mauris dapibus, sed porttitor ex dapibus. Phasellus sollicitudin eros erat, eu tincidunt tortor egestas ac. Praesent eget posuere mauris. Aenean et dictum nunc. Maecenas accumsan lorem sit amet orci scelerisque vulputate. Suspendisse sollicitudin pharetra aliquet. Ut egestas eleifend ante viverra cursus. Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Duis interdum ante sapien, ut rhoncus dolor vestibulum ac. Etiam sit amet consectetur magna. Vestibulum ex elit, gravida vitae ante nec, dapibus mollis felis. Donec ut fermentum metus. Nulla commodo augue nec eros tempus, sit amet vulputate leo tempor. Aliquam condimentum ligula vitae sapien maximus molestie. Aenean mattis suscipit sapien, quis laoreet ex dignissim ac. Pellentesque mattis feugiat felis, sed placerat lorem malesuada id. Cras egestas at odio ut efficitur. Curabitur nec urna eu felis tempus venenatis. Fusce in metus non tellus luctus fermentum. Nam ut dignissim massa. Mauris eget facilisis mi. Nam hendrerit ante vel dui tincidunt, eget ornare nisl tincidunt. Vestibulum consequat dui ac quam condimentum, et condimentum nulla porta. Aenean diam ex, ultricies a aliquam vitae, venenatis sed ante. Cras felis tortor, viverra id neque et, sagittis aliquet neque. Mauris urna arcu, efficitur nec viverra in, venenatis sit amet magna. In viverra, nulla lobortis elementum efficitur, justo diam lacinia ipsum, ut sodales mi est ac orci. Pellentesque egestas mi a libero aliquet cursus. Lorem ipsum dolor sit amet, consectetur adipiscing elit sed.";
                            print(lorem_ipsum.length);
                            _manager.broadcast(lorem_ipsum);
                          },
                        ),
                      ),

                      Expanded(
                        child: ListView(
                          children: _playlist.map((pair) {
                            return Card(
                              child: ListTile(
                                title: Center(child: Text(pair.last)),
                                subtitle: Center(child: Text(pair.first)),
                                onTap: () => setState(() => _selected = pair.last),
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

  void _processAdHocEvent(AdHocEvent event) {
    switch (event.type) {
      case DISCOVERY_END:
        setState(() {
          (event.payload as Map).entries.forEach(
            (element) => _discovered.add(element.value)
          );
        });
        break;

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
        List peers = data['peers'] as List;
        List songs = data['songs'] as List;
        String peerName = peers.first;
        HashMap<String, PlatformFile> entry = _globalPlaylist[peerName];
        if (entry == null)
          entry = HashMap();

        for (int i = 0; i < peers.length; i++) {
          if (peerName == peers[i]) {
            entry.putIfAbsent(songs[i], () => null);
          } else {
            _globalPlaylist[peerName == LOCAL ? peer.label : peerName] = entry;

            peerName = peers[i];
            entry = _globalPlaylist[peerName == LOCAL ? peer.label : peerName];
            if (entry == null)
              entry = HashMap();
            entry.putIfAbsent(songs[i], () => null);
          }

          Pair<String, String> pair = Pair(peerName, songs[i]);
          if (!_playlist.contains(pair))
            _playlist.add(pair);
        }

        _globalPlaylist[peerName == LOCAL ? peer.label : peerName] = entry;

        setState(() {});
        break;

      case REQUEST:
        // TODO: if this node has the requested song, it can send instead of the originated node
        String name = data['name'];
        Uint8List bytes;
        // PlatformFile file;

        if (_localPlaylist.containsKey(name)) {
          bytes = _localPlaylist[name].bytes;
        }

        // else {
        //   for (int i = 0; i < _globalPlaylist.length; i++) {
        //     Map entry = _globalPlaylist[i];
        //     if (entry.containsKey(name)) {
        //       file = entry[name];
        //       if (file == null) {
        //         HashMap<String, dynamic> message = HashMap();
        //         message.putIfAbsent('type', () => REQUEST);
        //         message.putIfAbsent('name', () => name);
        //         // Send label of requester too so that originated node send directly
        //         _manager.sendMessageTo(message, _globalPlaylist.keys.elementAt(i));
        //         _peerRequest = true;
        //       }

        //       break;
        //     }
        //   }
        // }

        HashMap<String, dynamic> message = HashMap();
        message.putIfAbsent('type', () => REPLY);
        message.putIfAbsent('name', () => name);
        message.putIfAbsent('song', () => bytes);
        _manager.sendMessageTo(message, peer.label);
        // _manager.sendEncryptedMessageTo(message, peer.label);
        break;

      case REPLY:
        _processReply(peer, data);
        break;

      default:
    }
  }

  void _processReply(AdHocDevice peer, Map data) async {
    // TODO: Requester node should wait for multiple possible request so check with name of file
    String name = data['name'];
    Uint8List song = Uint8List.fromList((data['song'] as List<dynamic>).cast<int>());

    Directory tempDir = await getTemporaryDirectory();
    File tempFile = File('${tempDir.path}/$name');
    await tempFile.writeAsBytes(song, flush: true);

    HashMap<String, PlatformFile> entry = HashMap();
    entry.putIfAbsent(
      name, () => PlatformFile(bytes: song, name: name, path: tempFile.path)
    );

    _globalPlaylist.update(peer.label, (value) => entry, ifAbsent: () => entry);
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
        Pair<String, String> pair = Pair(_name, file.name);
        if (!_playlist.contains(pair))
          _playlist.add(pair);
      }
    }

    _updatePlaylist();
  }

  void _updatePlaylist() async {
    List<String> peers = List.empty(growable: true);
    List<String> songs = List.empty(growable: true);

    _globalPlaylist.forEach((peer, song) {
      peers.add(peer);
      song.forEach((key, value) {
        songs.add(key);
      });
    });

    _localPlaylist.forEach((name, file) {
      peers.add(_name);
      songs.add(name);
    });

    HashMap<String, dynamic> message = HashMap();
    message.putIfAbsent('type', () => PLAYLIST);
    message.putIfAbsent('peers', () => peers);
    message.putIfAbsent('songs', () => songs);
    _manager.broadcast(message);
  }

  void _play() {
    if (_selected.compareTo(NONE) == 0)
      return;

    PlatformFile file;
    if (_localPlaylist.containsKey(_selected)) {
      file = _localPlaylist[_selected];
    } else {
      _globalPlaylist.forEach((peerName, playlist) {
        if (playlist.containsKey(_selected)) {
          file = playlist[_selected];
          if (file == null) {
            HashMap<String, dynamic> message = HashMap();
            message.putIfAbsent('type', () => REQUEST);
            message.putIfAbsent('name', () => _selected);
            _manager.broadcast(message);

            setState(() => _requested = true);
          }
        }
      });
    }

    if (_requested == false)
      platform.invokeMethod('play', file.path);
  }

  void _pause() {
    if (_selected.compareTo(NONE) == 0)
      return;

    platform.invokeMethod('pause');
  }

  void _stop() {
    if (_selected.compareTo(NONE) == 0)
      return;

    _selected = NONE;
    platform.invokeMethod('stop');

    setState(() {});
  }
}
