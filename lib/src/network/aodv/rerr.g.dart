// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rerr.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RERR _$RERRFromJson(Map<String, dynamic> json) {
  return RERR(
    type: json['type'] as int,
    unreachableDestIpAddress: json['unreachableDestIpAddress'] as String,
    unreachableDestSeqNum: json['unreachableDestSeqNum'] as int,
  );
}

Map<String, dynamic> _$RERRToJson(RERR instance) => <String, dynamic>{
      'type': instance.type,
      'unreachableDestIpAddress': instance.unreachableDestIpAddress,
      'unreachableDestSeqNum': instance.unreachableDestSeqNum,
    };
