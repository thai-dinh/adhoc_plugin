// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'msg_adhoc.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MessageAdHoc _$MessageAdHocFromJson(Map<String, dynamic> json) {
  return MessageAdHoc(
    Header.fromJson(json['header'] as Map<String, dynamic>),
    json['pdu'],
  );
}

Map<String, dynamic> _$MessageAdHocToJson(MessageAdHoc instance) =>
    <String, dynamic>{
      'header': instance.header.toJson(),
      'pdu': instance.pdu,
    };
