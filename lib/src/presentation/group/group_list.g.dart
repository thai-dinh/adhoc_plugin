// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupList _$GroupListFromJson(Map<String, dynamic> json) {
  return GroupList(
    (json['labels'] as List<dynamic>).map((e) => e as String).toList(),
  );
}

Map<String, dynamic> _$GroupListToJson(GroupList instance) => <String, dynamic>{
      'labels': instance.labels,
    };
