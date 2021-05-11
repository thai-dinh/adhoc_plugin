class DiscoveryEvent {
  int _type;
  Object? _payload;

  DiscoveryEvent(this._type, this._payload);

/*------------------------------Getters & Setters-----------------------------*/

  int get type => _type;

  Object? get payload => _payload;
}
