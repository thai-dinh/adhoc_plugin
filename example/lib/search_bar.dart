import 'package:flutter/material.dart';


class SearchBar extends SearchDelegate<String> {
  final List<String> _playlist;

  late List<String> _recentPick;
  String _selected = '';

  SearchBar(this._playlist) {
    _recentPick = List.empty(growable: true);
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
    close(context, _selected);
    return Container();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    var suggestions = List<String>.empty(growable: true);

    if (query.isEmpty) {
      suggestions = _recentPick;
    } else {
      var songNames = List<String>.empty(growable: true);
      for (var name in _playlist) {
        songNames.add(name);
      }

      suggestions.addAll(songNames.where((element) => element.contains(query)));
    }

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
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
