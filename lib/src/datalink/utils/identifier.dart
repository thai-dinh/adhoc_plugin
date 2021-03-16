import 'package:json_annotation/json_annotation.dart';

part 'identifier.g.dart';


@JsonSerializable()
class Identifier {
  String ble;
  String wifi;

  Identifier({this.ble = '', this.wifi = ''});

  factory Identifier.fromJson(Map<String, dynamic> json) => _$IdentifierFromJson(json);

/*-------------------------------Public methods-------------------------------*/

  Map<String, dynamic> toJson() => _$IdentifierToJson(this);

/*------------------------------Override methods------------------------------*/

  @override
  String toString() => 'ble=$ble/wifi=$wifi';
}
