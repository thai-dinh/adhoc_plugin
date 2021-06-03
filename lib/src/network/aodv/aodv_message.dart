/// Class representing an abstract AODV message for the AODV protocol.
abstract class AodvMessage {
  late int _type;

  /// Creates an [AodvMessage] object.
  /// 
  /// The type of message is specified by [type]. 
  AodvMessage(int type) {
    _type = type;
  }

/*------------------------------Getters & Setters-----------------------------*/

  /// Type of the AODV message.
  int get type => _type;
}
