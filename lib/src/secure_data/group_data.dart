import 'package:json_annotation/json_annotation.dart';

part 'group_data.g.dart';


@JsonSerializable()
class GroupData {
  String? leader;
  int? groupId;
  Object? data;

  GroupData(this.leader, this.groupId, this.data);

  factory GroupData.fromJson(Map<String, dynamic> json) => _$GroupDataFromJson(json);

/*-------------------------------Public methods-------------------------------*/

  Map<String, dynamic> toJson() => _$GroupDataToJson(this);
}
