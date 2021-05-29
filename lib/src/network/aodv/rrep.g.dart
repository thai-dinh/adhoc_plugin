// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rrep.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RREP _$RREPFromJson(Map<String, dynamic> json) {
  return RREP(
    json['type'] as int,
    json['hopCount'] as int,
    json['dstAddr'] as String,
    json['seqNum'] as int,
    json['srcAddr'] as String,
    json['lifetime'] as int,
    (json['chain'] as List<dynamic>)
        .map((e) => Certificate.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

Map<String, dynamic> _$RREPToJson(RREP instance) => <String, dynamic>{
      'type': instance.type,
      'chain': instance.chain,
      'hopCount': instance.hopCount,
      'seqNum': instance.seqNum,
      'lifetime': instance.lifetime,
      'dstAddr': instance.dstAddr,
      'srcAddr': instance.srcAddr,
    };
