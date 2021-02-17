// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'adhoc_device.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdHocDevice _$AdHocDeviceFromJson(Map<String, dynamic> json) {
  return AdHocDevice(
    name: json['name'] as String,
    mac: json['mac'] as String,
    type: json['type'] as int,
    directedConnected: json['directedConnected'] as bool,
    label: json['label'] as String,
    address: json['address'] as String,
  );
}

Map<String, dynamic> _$AdHocDeviceToJson(AdHocDevice instance) =>
    <String, dynamic>{
      'directedConnected': instance.directedConnected,
      'label': instance.label,
      'name': instance.name,
      'mac': instance.mac,
      'address': instance.address,
      'type': instance.type,
    };
