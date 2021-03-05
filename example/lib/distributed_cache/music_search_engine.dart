import 'package:flutter/material.dart';

class MusicSearchEngine extends StatefulWidget {
  @override
  _MusicSearchEngineState createState() => _MusicSearchEngineState();
}

class _MusicSearchEngineState extends State<MusicSearchEngine> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Center(child: Text('Ad Hoc Music Client'))),
      body: new IconButton(icon: new Icon(Icons.arrow_forward), onPressed: (){ }),
    );
  }
}
