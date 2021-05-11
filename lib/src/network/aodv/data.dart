import 'package:json_annotation/json_annotation.dart';

part 'data.g.dart';


@JsonSerializable()
class Data {
  String? destAddress;
  Object? payload;

  Data(this.destAddress, this.payload);

  factory Data.fromJson(Map<String, dynamic> json) => _$DataFromJson(json);

/*-------------------------------Public methods-------------------------------*/

  Map<String, dynamic> toJson() => _$DataToJson(this);

/*------------------------------Override methods------------------------------*/

  @override
  String toString() {
    return 'Data{' +
            'destAddress=$destAddress' +
            ', payload=${payload.toString()}' +
          '}';
  }
}