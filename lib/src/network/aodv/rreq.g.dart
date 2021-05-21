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
    json['destSequenceNum'] as int,
    json['destAddress'] as String,
    json['originSequenceNum'] as int,
    json['originAddress'] as String,
    (json['certChain'] as List<dynamic>)
        .map((e) => Certificate.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

Map<String, dynamic> _$RREQToJson(RREQ instance) => <String, dynamic>{
      'type': instance.type,
      'destSequenceNum': instance.destSequenceNum,
      'certChain': instance.certChain,
      'hopCount': instance.hopCount,
      'rreqId': instance.rreqId,
      'destAddress': instance.destAddress,
      'originSequenceNum': instance.originSequenceNum,
      'originAddress': instance.originAddress,
    };
