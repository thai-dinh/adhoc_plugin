// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'msg_header.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Header _$HeaderFromJson(Map<String, dynamic> json) {
  return Header(
    messageType: json['messageType'] as int,
    label: json['label'] as String,
    seqNum: json['seqNum'] as int?,
    name: json['name'] as String?,
    address: json['address'] as String?,
    mac: json['mac'] == null
        ? null
        : Identifier.fromJson(json['mac'] as Map<String, dynamic>),
    deviceType: json['deviceType'] as int?,
  );
}

Map<String, dynamic> _$HeaderToJson(Header instance) => <String, dynamic>{
      'messageType': instance.messageType,
      'seqNum': instance.seqNum,
      'address': instance.address,
      'deviceType': instance.deviceType,
      'label': instance.label,
      'name': instance.name,
      'mac': instance.mac,
    };
