// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Data _$DataFromJson(Map<String, dynamic> json) {
  return Data(
    json['dstAddress'] as String?,
    json['payload'],
  );
}

Map<String, dynamic> _$DataToJson(Data instance) => <String, dynamic>{
      'dstAddress': instance.dstAddress,
      'payload': instance.payload,
    };
