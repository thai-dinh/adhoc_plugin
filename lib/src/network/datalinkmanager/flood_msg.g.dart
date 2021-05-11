// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flood_msg.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FloodMsg _$FloodMsgFromJson(Map<String, dynamic> json) {
  return FloodMsg(
    json['id'] as String?,
    const _HashSetConverter()
        .fromJson(json['adHocDevices'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$FloodMsgToJson(FloodMsg instance) => <String, dynamic>{
      'adHocDevices': const _HashSetConverter().toJson(instance.adHocDevices!),
      'id': instance.id,
    };
