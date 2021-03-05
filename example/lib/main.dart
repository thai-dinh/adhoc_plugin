import 'package:flutter/material.dart';

void main() => runApp(AdHocMusicClient());

class AdHocMusicClient extends StatefulWidget {
  @override
  _AdHocMusicClientState createState() => _AdHocMusicClientState();
}

class _AdHocMusicClientState extends State<AdHocMusicClient> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ad Hoc Music Client',
      home: Scaffold(
        appBar: AppBar(
          title: Text('Welcome to Flutter'),
        ),
        body: Center(
          child: Text('Hello World'),
        ),
      ),
    );
  }
}
