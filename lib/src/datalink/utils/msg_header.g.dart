// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'msg_header.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Header _$HeaderFromJson(Map<String, dynamic> json) {
  return Header(
    messageType: json['messageType'] as int,
    label: json['label'] as String,
    name: json['name'] as String,
    address: json['address'] as String,
    mac: json['mac'] as String,
    ulid: json['ulid'] as String,
    deviceType: json['deviceType'] as int,
  );
}

Map<String, dynamic> _$HeaderToJson(Header instance) => <String, dynamic>{
      'deviceType': instance.deviceType,
      'messageType': instance.messageType,
      'label': instance.label,
      'name': instance.name,
      'address': instance.address,
      'mac': instance.mac,
      'ulid': instance.ulid,
    };
