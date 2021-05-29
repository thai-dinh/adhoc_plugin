// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Data _$DataFromJson(Map<String, dynamic> json) {
  return Data(
    json['dstAddr'] as String?,
    json['payload'],
  );
}

Map<String, dynamic> _$DataToJson(Data instance) => <String, dynamic>{
      'dstAddr': instance.dstAddr,
      'payload': instance.payload,
    };
