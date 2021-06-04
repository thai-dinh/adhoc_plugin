import 'dart:convert';
import 'dart:typed_data';

import 'package:adhoc_plugin/src/presentation/certificate.dart';
import 'package:adhoc_plugin/src/presentation/crypto_engine.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pointycastle/pointycastle.dart';


void main() {
  final string = 'Hello world!';

  late CryptoEngine cryptoEngine;
  late RSAPublicKey rsaPublicKey;
  late SecretKey secretKey;
  late Certificate certificate;

  setUp(() async {
    cryptoEngine = CryptoEngine();
    await cryptoEngine.initialize();
    rsaPublicKey = cryptoEngine.generateRSAkeyPair().publicKey;
    final algorithm = Chacha20.poly1305Aead();
    secretKey = await algorithm.newSecretKey();
    certificate = Certificate('owner', 'issuer', DateTime.now(), rsaPublicKey);
  });

  tearDown(() {
    cryptoEngine.stop();
  });

  test('encrypt() and decrypt() test', () async {
    var encrypted = await cryptoEngine.encrypt(
      Uint8List.fromList(utf8.encode(string)), publicKey: cryptoEngine.publicKey
    );

    var result = utf8.decode(await cryptoEngine.decrypt(encrypted));

    expect(result, string);

    encrypted = await cryptoEngine.encrypt(
      Uint8List.fromList(utf8.encode(string)), sharedKey: secretKey
    );

    result = utf8.decode(
      await cryptoEngine.decrypt(encrypted, sharedKey: secretKey)
    );

    expect(result, string);
  });

  test('sign() and verify() test', () {
    var signature = cryptoEngine.sign(
      Uint8List.fromList(Utf8Encoder().convert(rsaPublicKey.toString()))
    );

    certificate.signature = signature;

    expect(
      cryptoEngine.verify(certificate, signature, cryptoEngine.publicKey), true
    );
  });
}
