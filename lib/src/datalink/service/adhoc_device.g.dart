// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'adhoc_device.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdHocDevice _$AdHocDeviceFromJson(Map<String, dynamic> json) {
  return AdHocDevice(
    label: json['label'] as String?,
    address: json['address'] as String?,
    name: json['name'] as String?,
    mac: json['mac'] as String?,
    type: json['type'] as int,
  );
}

Map<String, dynamic> _$AdHocDeviceToJson(AdHocDevice instance) =>
    <String, dynamic>{
      'address': instance.address,
      'label': instance.label,
      'name': instance.name,
      'mac': instance.mac,
      'type': instance.type,
    };
