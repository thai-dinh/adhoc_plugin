import 'dart:typed_data';

import 'package:pointycastle/pointycastle.dart';


class Certificate {
  String _owner;
  String _issuer;
  DateTime _validity;
  RSAPublicKey _key;

  Uint8List signature;

  Certificate(this._owner, this._issuer, this._key) {
    this.signature = Uint8List(1);
  }

/*------------------------------Getters & Setters-----------------------------*/

  String get owner => _owner;

  String get issuer => _issuer;

  DateTime get validity => _validity;

  RSAPublicKey get key => _key;
}
