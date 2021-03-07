import 'package:flutter/material.dart';


class MusicSearchEngine extends StatefulWidget {
  final List<String> _songs;

  MusicSearchEngine(this._songs);

  @override
  _MusicSearchEngineState createState() => _MusicSearchEngineState(_songs);
}

class _MusicSearchEngineState extends State<MusicSearchEngine> {
  final List<String> _songs;

  _MusicSearchEngineState(this._songs);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Ad Hoc Music Client'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(context: context, delegate: SearchEngine(_songs));
            }
          ),
        ],
      ),
      body: ListView(

      ),
    );
  }
}

class SearchEngine extends SearchDelegate {
  List<String> _songs;
  String _selected = '';

  SearchEngine(this._songs);

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
        child: Text(_selected),
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Text('To do');
  }
}
