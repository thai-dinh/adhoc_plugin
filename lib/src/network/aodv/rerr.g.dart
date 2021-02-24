// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rerr.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RERR _$RERRFromJson(Map<String, dynamic> json) {
  return RERR(
    type: json['type'] as int,
    unreachableDestAddress: json['unreachableDestAddress'] as String,
    unreachableDestSeqNum: json['unreachableDestSeqNum'] as int,
  );
}

Map<String, dynamic> _$RERRToJson(RERR instance) => <String, dynamic>{
      'type': instance.type,
      'unreachableDestAddress': instance.unreachableDestAddress,
      'unreachableDestSeqNum': instance.unreachableDestSeqNum,
    };
