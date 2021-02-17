// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rreq.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RREQ _$RREQFromJson(Map<String, dynamic> json) {
  return RREQ(
    type: json['type'] as int,
    hopCount: json['hopCount'] as int,
    rreqId: json['rreqId'] as int,
    destSequenceNum: json['destSequenceNum'] as int,
    destIpAddress: json['destIpAddress'] as String,
    originSequenceNum: json['originSequenceNum'] as int,
    originIpAddress: json['originIpAddress'] as String,
  );
}

Map<String, dynamic> _$RREQToJson(RREQ instance) => <String, dynamic>{
      'type': instance.type,
      'hopCount': instance.hopCount,
      'rreqId': instance.rreqId,
      'destSequenceNum': instance.destSequenceNum,
      'destIpAddress': instance.destIpAddress,
      'originSequenceNum': instance.originSequenceNum,
      'originIpAddress': instance.originIpAddress,
    };
