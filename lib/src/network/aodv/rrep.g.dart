// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rrep.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RREP _$RREPFromJson(Map<String, dynamic> json) {
  return RREP(
    json['type'] as int,
    json['hopCount'] as int,
    json['destAddress'] as String,
    json['sequenceNum'] as int,
    json['originAddress'] as String,
    json['lifetime'] as int,
  );
}

Map<String, dynamic> _$RREPToJson(RREP instance) => <String, dynamic>{
      'type': instance.type,
      'hopCount': instance.hopCount,
      'sequenceNum': instance.sequenceNum,
      'lifetime': instance.lifetime,
      'destAddress': instance.destAddress,
      'originAddress': instance.originAddress,
    };
