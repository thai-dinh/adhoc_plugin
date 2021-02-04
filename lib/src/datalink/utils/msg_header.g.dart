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
    macAddress: json['macAddress'] as String,
    deviceType: json['deviceType'] as int,
  );
}

Map<String, dynamic> _$HeaderToJson(Header instance) => <String, dynamic>{
      'messageType': instance.messageType,
      'deviceType': instance.deviceType,
      'label': instance.label,
      'name': instance.name,
      'address': instance.address,
      'macAddress': instance.macAddress,
    };
