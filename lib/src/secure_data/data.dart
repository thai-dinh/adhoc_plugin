class Data {
  int _type;
  Object _payload;
  
  Data(this._type, this._payload);

  int get type => _type;

  Object get payload => _payload;
}
