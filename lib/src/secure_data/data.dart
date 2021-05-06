import 'package:json_annotation/json_annotation.dart';

part 'data.g.dart';


@JsonSerializable()
class Data {
  int type;
  Object payload;
  
  Data(this.type, this.payload);

  factory Data.fromJson(Map<String, dynamic> json) => _$DataFromJson(json);

/*-------------------------------Public methods-------------------------------*/

  Map<String, dynamic> toJson() => _$DataToJson(this);

}
