// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_join.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupJoin _$GroupJoinFromJson(Map<String, dynamic> json) {
  return GroupJoin(
    hash: json['hash'] as String?,
    labels:
        (json['labels'] as List<dynamic>?)?.map((e) => e as String).toList(),
    values:
        (json['values'] as List<dynamic>?)?.map((e) => e as String).toList(),
    share: json['share'] as String?,
    solution: json['solution'] as String?,
  );
}

Map<String, dynamic> _$GroupJoinToJson(GroupJoin instance) => <String, dynamic>{
      'hash': instance.hash,
      'labels': instance.labels,
      'values': instance.values,
      'share': instance.share,
      'solution': instance.solution,
    };
