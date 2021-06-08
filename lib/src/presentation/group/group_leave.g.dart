// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_leave.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupLeave _$GroupLeaveFromJson(Map<String, dynamic> json) {
  return GroupLeave(
    json['leavingLabel'] as String,
    newSolution: json['newSolution'] as String?,
  );
}

Map<String, dynamic> _$GroupLeaveToJson(GroupLeave instance) =>
    <String, dynamic>{
      'leavingLabel': instance.leavingLabel,
      'newSolution': instance.newSolution,
    };
