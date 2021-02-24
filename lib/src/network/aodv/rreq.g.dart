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
    destAddress: json['destAddress'] as String,
    originSequenceNum: json['originSequenceNum'] as int,
    originAddress: json['originAddress'] as String,
  );
}

Map<String, dynamic> _$RREQToJson(RREQ instance) => <String, dynamic>{
      'type': instance.type,
      'destSequenceNum': instance.destSequenceNum,
      'hopCount': instance.hopCount,
      'rreqId': instance.rreqId,
      'destAddress': instance.destAddress,
      'originSequenceNum': instance.originSequenceNum,
      'originAddress': instance.originAddress,
    };
