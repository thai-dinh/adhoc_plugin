// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rreq.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RREQ _$RREQFromJson(Map<String, dynamic> json) {
  return RREQ(
    json['type'] as int,
    json['hopCount'] as int,
    json['rreqId'] as int,
    json['dstSeqNum'] as int,
    json['dstAddr'] as String,
    json['srcSeqNum'] as int,
    json['srcAddr'] as String,
    json['ttl'] as int,
    (json['chain'] as List<dynamic>)
        .map((e) => Certificate.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

Map<String, dynamic> _$RREQToJson(RREQ instance) => <String, dynamic>{
      'type': instance.type,
      'dstSeqNum': instance.dstSeqNum,
      'ttl': instance.ttl,
      'chain': instance.chain,
      'hopCount': instance.hopCount,
      'rreqId': instance.rreqId,
      'dstAddr': instance.dstAddr,
      'srcSeqNum': instance.srcSeqNum,
      'srcAddr': instance.srcAddr,
    };
