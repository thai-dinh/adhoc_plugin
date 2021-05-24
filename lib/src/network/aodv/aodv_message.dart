import 'package:json_annotation/json_annotation.dart';

part 'aodv_message.g.dart';


/// Class representing an abstract AODV message for the AODV protocol.
@JsonSerializable()
class AodvMessage {
  late int _type;

  /// Creates an [AodvMessage] object.
  /// 
  /// The type of message is specified by [type]. 
  AodvMessage(int type) {
    this._type = type;
  }

  /// Creates a [AodvMessage] object from a JSON representation.
  /// 
  /// Factory constructor that creates a [AodvMessage] based on the 
  /// information given by [json].
  factory AodvMessage.fromJson(Map<String, dynamic> json) => _$AodvMessageFromJson(json);

/*------------------------------Getters & Setters-----------------------------*/

  /// Returns the type of the AODV message.
  int get type => _type;

/*-------------------------------Public methods-------------------------------*/

  /// Returns the JSON representation as a [Map] of this [AodvMessage] instance.
  Map<String, dynamic> toJson() => _$AodvMessageToJson(this);
}
