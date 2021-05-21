class AdHocEvent {
  Object? payload;

  late int type;

  AdHocEvent(this.type, this.payload);

  AdHocEvent.fromMap(Map map) {
    this.type = map['type'];
    this.payload = map['payload'];
  }
}
