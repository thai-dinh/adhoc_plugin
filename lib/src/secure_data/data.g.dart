// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Data _$DataFromJson(Map<String, dynamic> json) {
  return Data(
    json['type'] as int?,
    json['payload'],
  );
}

Map<String, dynamic> _$DataToJson(Data instance) => <String, dynamic>{
      'type': instance.type,
      'payload': instance.payload,
    };
