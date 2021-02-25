import 'dart:collection';


class EntryRoutingTable {
  String _destAddress;
  String _next;
  int _hop;
  int _destSeqNum;
  int _lifetime;
  List<String> _precursors;
  HashMap<String, int> _activesDataPath;

  EntryRoutingTable(
    this._destAddress, this._next, this._hop, this._destSeqNum,
    this._lifetime, this._precursors
  ) {
    this._activesDataPath = HashMap();
  }

/*------------------------------Getters & Setters-----------------------------*/

  String get destAddress => _destAddress;

  String get next => _next;

  int get hop => _hop;

  int get destSeqNum => _destSeqNum;

  int get lifetime => _lifetime;

  List<String> get precursors => _precursors;

/*------------------------------Public methods-------------------------------*/

  void updateDataPath(String key) {
    _activesDataPath.putIfAbsent(key, () => DateTime.now().millisecond);
  }

  int getActivesDataPath(String address) {
    if (_activesDataPath.containsKey(address))
      return _activesDataPath[address];
    return 0;
  }

  void updatePrecursors(String senderAddr) {
    if (_precursors == null) {
      _precursors = new List();
      _precursors.add(senderAddr);
    } else if (!_precursors.contains(senderAddr)) {
      _precursors.add(senderAddr);
    }
  }

  String displayPrecursors() {
    if (_precursors == null)
      return '';
    return '';
  }

/*------------------------------Override methods------------------------------*/

  @override
  String toString() {
    return '- dst: $_destAddress' +
            ' nxt: $_next' +
            ' hop: $_hop' +
            ' seq: $_destSeqNum ${displayPrecursors()}' +
            ' dataPath $_activesDataPath[_destAddress]';
  }
}
