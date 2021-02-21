import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'data.g.dart';


@JsonSerializable()
class Data {
  String destIpAddress;
  Object payload;

  Data({@required String destIpAddress, @required Object payload}) {
    this.destIpAddress = destIpAddress;
    this.payload = payload;
  }

 factory Data.fromJson(Map<String, dynamic> json) => _$DataFromJson(json);

/*-------------------------------Public methods-------------------------------*/

  Map<String, dynamic> toJson() => _$DataToJson(this);

/*------------------------------Override methods------------------------------*/

  @override
  String toString() {
    return 'Data{' +
            'destIpAddress=' + destIpAddress +
            ', payload=' + payload.toString() +
          '}';
  }
}