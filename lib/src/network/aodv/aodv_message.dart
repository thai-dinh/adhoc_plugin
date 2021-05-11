import 'package:json_annotation/json_annotation.dart';

part 'aodv_message.g.dart';


@JsonSerializable()
class AodvMessage {
  int? _type;

  AodvMessage(int? type) {
    this._type = type;
  }

  factory AodvMessage.fromJson(Map<String, dynamic> json) => _$AodvMessageFromJson(json);

/*------------------------------Getters & Setters-----------------------------*/

  int? get type => _type;

/*-------------------------------Public methods-------------------------------*/

  Map<String, dynamic> toJson() => _$AodvMessageToJson(this);
}
