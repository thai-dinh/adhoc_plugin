// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'secure_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SecureData _$SecureDataFromJson(Map<String, dynamic> json) {
  return SecureData(
    json['type'] as int,
    json['payload'],
  );
}

Map<String, dynamic> _$SecureDataToJson(SecureData instance) =>
    <String, dynamic>{
      'payload': instance.payload,
      'type': instance.type,
    };
