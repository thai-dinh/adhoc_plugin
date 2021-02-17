// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Data _$DataFromJson(Map<String, dynamic> json) {
  return Data(
    destIpAddress: json['destIpAddress'] as String,
    payload: json['payload'],
  );
}

Map<String, dynamic> _$DataToJson(Data instance) => <String, dynamic>{
      'destIpAddress': instance.destIpAddress,
      'payload': instance.payload,
    };
