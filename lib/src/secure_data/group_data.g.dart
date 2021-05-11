// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupData _$GroupDataFromJson(Map<String, dynamic> json) {
  return GroupData(
    json['leader'] as String?,
    json['groupId'] as int?,
    json['data'],
  );
}

Map<String, dynamic> _$GroupDataToJson(GroupData instance) => <String, dynamic>{
      'leader': instance.leader,
      'groupId': instance.groupId,
      'data': instance.data,
    };
