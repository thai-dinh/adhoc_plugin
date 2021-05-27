// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'msg_header.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Header _$HeaderFromJson(Map<String, dynamic> json) {
  return Header(
    messageType: json['messageType'] as int,
    label: json['label'] as String,
    name: json['name'] as String?,
    address: json['address'] as String?,
    mac: json['mac'] == null
        ? null
        : Identifier.fromJson(json['mac'] as Map<String, dynamic>),
    deviceType: json['deviceType'] as int?,
  );
}

Map<String, dynamic> _$HeaderToJson(Header instance) => <String, dynamic>{
      'address': instance.address,
      'deviceType': instance.deviceType,
      'messageType': instance.messageType,
      'label': instance.label,
      'name': instance.name,
      'mac': instance.mac,
    };
