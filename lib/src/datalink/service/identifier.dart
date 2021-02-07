class Identifier {
  String _mac;
  String _ulid;

  Identifier({String mac = '', String ulid = ''}) {
    this._mac = mac;
    this._ulid = ulid;
  }

  String get mac => _mac;

  String get ulid => _ulid;
}
