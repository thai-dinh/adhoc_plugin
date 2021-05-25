import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';
import 'package:pointycastle/export.dart';

part 'certificate.g.dart';


/// Class representing a digital certificate.
@JsonSerializable()
class Certificate {
  late String _owner;
  late String _issuer;
  late DateTime _validity;
  @_PublicKeyConverter()
  late RSAPublicKey _key;
  @_Uint8ListConverter()
  late Uint8List signature;

  /// Creates a [Certificate] object.
  /// 
  /// The certificate is bound to the [owner] label, which has been issued by
  /// [issuer]. The certificate is valid until [validity] date time. This
  /// certificate acknowledges the binding of identity of [owner] with the 
  /// public key [key].
  Certificate(
    String owner, String issuer, DateTime validity, RSAPublicKey key
  ) {
    this._owner = owner;
    this._issuer = issuer;
    this._validity = validity;
    this._key = key;
    this.signature = Uint8List(1);
  }

  /// Creates a [Certificate] object from a JSON representation.
  /// 
  /// Factory constructor that creates a [Certificate] based on the information 
  /// given by [json].
  factory Certificate.fromJson(Map<String, dynamic> json) => _$CertificateFromJson(json);

/*------------------------------Getters & Setters-----------------------------*/

  /// Returns the owner label of the certificate.
  String get owner => _owner;

  /// Returns the issuer label of the certificate.
  String get issuer => _issuer;

  /// Returns the validity date time of the certificate.
  DateTime get validity => _validity;

  /// Returns the owner public key of the certificate.
  @_PublicKeyConverter()
  RSAPublicKey get key => _key;

/*-------------------------------Public methods-------------------------------*/

  /// Returns the JSON representation as a [Map] of this [Certificate] instance.
  Map<String, dynamic> toJson() => _$CertificateToJson(this);
}


class _PublicKeyConverter implements JsonConverter<RSAPublicKey, Map<String, dynamic>> {
  const _PublicKeyConverter();

  @override
  RSAPublicKey fromJson(Map<String, dynamic> json) {
    BigInt modulus = BigInt.parse(json['modulus'] as String);
    BigInt exponent = BigInt.parse(json['exponent'] as String);
    return RSAPublicKey(modulus, exponent);
  }

  @override
  Map<String, dynamic> toJson(RSAPublicKey key) {
    Map<String, dynamic> map = Map();

    map['modulus'] = key.modulus.toString();
    map['exponent'] = key.exponent.toString();

    return map;
  }
}


class _Uint8ListConverter implements JsonConverter<Uint8List, List<int>> {
  const _Uint8ListConverter();

  @override
  Uint8List fromJson(List<int> json) {
    return Uint8List.fromList(json);
  }

  @override
  List<int> toJson(Uint8List object) {
    return object.toList();
  }
}