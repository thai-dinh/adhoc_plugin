import 'package:json_annotation/json_annotation.dart';

part 'secure_data.g.dart';


@JsonSerializable()
class SecureData {
  Object? payload;

  late int type;

  SecureData(this.type, this.payload);

  factory SecureData.fromJson(Map<String, dynamic> json) 
    => _$SecureDataFromJson(json);

/*-------------------------------Public methods-------------------------------*/

  Map<String, dynamic> toJson() => _$SecureDataToJson(this);
}
