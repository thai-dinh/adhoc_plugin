// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'msg_header.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Header _$HeaderFromJson(Map<String, dynamic> json) {
  return Header(
    json['messageType'] as int,
    json['label'] as String,
    json['name'] as String,
    json['address'] as String,
    json['uuid'] as String,
  );
}

Map<String, dynamic> _$HeaderToJson(Header instance) => <String, dynamic>{
      'messageType': instance.messageType,
      'label': instance.label,
      'name': instance.name,
      'address': instance.address,
      'uuid': instance.uuid,
    };
