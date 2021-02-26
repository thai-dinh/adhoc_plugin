class AdHocEvent {
  int _type;
  Object _payload;
  Object _extra;

  AdHocEvent(this._type, this._payload, {Object extra}) {
    this._extra = extra;
  }

/*------------------------------Getters & Setters-----------------------------*/

  int get type => _type;

  Object get payload => _payload;

  Object get extra => _extra;
}
