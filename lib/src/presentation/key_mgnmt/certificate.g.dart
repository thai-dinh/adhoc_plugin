// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'certificate.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Certificate _$CertificateFromJson(Map<String, dynamic> json) {
  return Certificate(
    json['owner'] as String,
    json['issuer'] as String,
    DateTime.parse(json['validity'] as String),
    const _PublicKeyConverter().fromJson(json['key'] as Map<String, dynamic>),
  )..signature = const _Uint8ListConverter()
      .fromJson((json['signature'] as List<dynamic>).cast<int>());
}

Map<String, dynamic> _$CertificateToJson(Certificate instance) =>
    <String, dynamic>{
      'signature': const _Uint8ListConverter().toJson(instance.signature),
      'owner': instance.owner,
      'issuer': instance.issuer,
      'validity': instance.validity.toIso8601String(),
      'key': const _PublicKeyConverter().toJson(instance.key),
    };
