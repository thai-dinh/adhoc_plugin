// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_init.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupInit _$GroupInitFromJson(Map<String, dynamic> json) {
  return GroupInit(
    json['timestamp'] as String,
    json['modulo'] as String,
    json['generator'] as String,
    json['initiator'] as String,
    json['invitation'] as bool,
  );
}

Map<String, dynamic> _$GroupInitToJson(GroupInit instance) => <String, dynamic>{
      'timestamp': instance.timestamp,
      'modulo': instance.modulo,
      'generator': instance.generator,
      'initiator': instance.initiator,
      'invitation': instance.invitation,
    };
