/// Class representing an ad hoc event.
class AdHocEvent {
  Object? payload;

  late int type;

  /// Creates a [AdHocEvent] object.
  /// 
  /// The type of event and the type of payload is determined by [type]. The
  /// event content is givne by [payload].
  AdHocEvent(this.type, this.payload);

  /// Creates a [AdHocEvent] object.
  /// 
  /// The ad hoc event is represented by information given by [map].
  AdHocEvent.fromMap(Map map) {
    this.type = map['type'];
    this.payload = map['payload'];
  }
}
