// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rrep.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RREP _$RREPFromJson(Map<String, dynamic> json) {
  return RREP(
    json['type'] as int,
    json['hopCount'] as int,
    json['dstAddress'] as String,
    json['seqNum'] as int,
    json['srcAddress'] as String,
    json['lifetime'] as int,
    (json['certChain'] as List<dynamic>)
        .map((e) => Certificate.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

Map<String, dynamic> _$RREPToJson(RREP instance) => <String, dynamic>{
      'type': instance.type,
      'certChain': instance.certChain,
      'hopCount': instance.hopCount,
      'seqNum': instance.seqNum,
      'lifetime': instance.lifetime,
      'dstAddress': instance.dstAddress,
      'srcAddress': instance.srcAddress,
    };
