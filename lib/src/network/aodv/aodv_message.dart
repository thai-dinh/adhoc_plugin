import 'package:json_annotation/json_annotation.dart';

part 'aodv_message.g.dart';


@JsonSerializable()
abstract class AodvMessage {
  int _type;

  AodvMessage(int type) {
    this._type = type;
  }

  int get type => _type;
}
