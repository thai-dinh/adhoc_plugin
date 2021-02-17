// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rrep.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RREP _$RREPFromJson(Map<String, dynamic> json) {
  return RREP(
    type: json['type'] as int,
    hopCount: json['hopCount'] as int,
    destIpAddress: json['destIpAddress'] as String,
    sequenceNum: json['sequenceNum'] as int,
    originIpAddress: json['originIpAddress'] as String,
    lifetime: json['lifetime'] as int,
  );
}

Map<String, dynamic> _$RREPToJson(RREP instance) => <String, dynamic>{
      'type': instance.type,
      'hopCount': instance.hopCount,
      'sequenceNum': instance.sequenceNum,
      'lifetime': instance.lifetime,
      'destIpAddress': instance.destIpAddress,
      'originIpAddress': instance.originIpAddress,
    };
