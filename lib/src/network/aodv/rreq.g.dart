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
    json['destSeqNum'] as int,
    json['dstAddress'] as String,
    json['srcSeqNum'] as int,
    json['srcAddress'] as String,
    (json['certChain'] as List<dynamic>)
        .map((e) => Certificate.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

Map<String, dynamic> _$RREQToJson(RREQ instance) => <String, dynamic>{
      'type': instance.type,
      'destSeqNum': instance.destSeqNum,
      'certChain': instance.certChain,
      'hopCount': instance.hopCount,
      'rreqId': instance.rreqId,
      'dstAddress': instance.dstAddress,
      'srcSeqNum': instance.srcSeqNum,
      'srcAddress': instance.srcAddress,
    };
