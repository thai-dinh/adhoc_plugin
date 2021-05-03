import 'package:pointycastle/pointycastle.dart';

class Certificate {
  String _owner;
  RSAPublicKey _key;

  Certificate(this._owner);

  String get owner => _owner;

  RSAPublicKey get key => key;
}
