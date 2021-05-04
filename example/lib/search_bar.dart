import 'package:flutter/material.dart';


class SearchBar extends SearchDelegate<String> {
  final List<String> _playlist;

  List<String> _recentPick;
  String _selected = '';

  SearchBar(this._playlist) {
    this._recentPick = List.empty(growable: true);
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return <Widget>[
      IconButton(
        icon: Icon(Icons.close), onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context),
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
      _playlist.forEach((name) => songNames.add(name));
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
