// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_adhoc.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MessageAdHoc _$MessageAdHocFromJson(Map<String, dynamic> json) {
  return MessageAdHoc()
    ..header = json['header'] == null
        ? null
        : Header.fromJson(json['header'] as Map<String, dynamic>);
}

Map<String, dynamic> _$MessageAdHocToJson(MessageAdHoc instance) =>
    <String, dynamic>{
      'header': instance.header,
    };
