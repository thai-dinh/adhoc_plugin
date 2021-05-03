import 'dart:math';
import 'dart:typed_data';

import "package:pointycastle/export.dart";


class CryptoEngine {
  RSAPublicKey _publicKey;
  RSAPrivateKey _privateKey;

  CryptoEngine() {
    final keys = generateRSAkeyPair(_randomEngine());
    this._publicKey = keys.publicKey;
    this._privateKey = keys.privateKey;
  }

/*------------------------------Getters & Setters-----------------------------*/

  RSAPublicKey get publicKey => _publicKey;

/*-------------------------------Public methods-------------------------------*/

  AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> generateRSAkeyPair(
    SecureRandom secureRandom, {int bitLength = 2048}
  ) {
    final keyGen = RSAKeyGenerator()..init(ParametersWithRandom(
      RSAKeyGeneratorParameters(BigInt.parse('65537'), bitLength, 64), 
      secureRandom
    ));

    final pair = keyGen.generateKeyPair();
    final publicKey = pair.publicKey as RSAPublicKey;
    final privateKey = pair.privateKey as RSAPrivateKey;

    return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(publicKey, privateKey);
  }

  Uint8List sign(Uint8List data) {
    final signer = RSASigner(SHA256Digest(), '0609608648016503040201');
    signer.init(true, PrivateKeyParameter<RSAPrivateKey>(_privateKey));
    return signer.generateSignature(data).bytes;
  }

  bool verify(Uint8List data, Uint8List signature, RSAPublicKey key) {
    final verifier = RSASigner(SHA256Digest(), '0609608648016503040201');
    verifier.init(false, PublicKeyParameter<RSAPublicKey>(key));

    try {
      return verifier.verifySignature(data, RSASignature(signature));
    } on ArgumentError {
      return false;
    }
  }

  Uint8List encrypt(Uint8List data, RSAPublicKey key) {
    final encryptor = OAEPEncoding(RSAEngine())
      ..init(true, PublicKeyParameter<RSAPublicKey>(key));
    return _processData(encryptor, data);
  }

  Uint8List decrypt(Uint8List data) {
    final decryptor = OAEPEncoding(RSAEngine())
      ..init(false, PrivateKeyParameter<RSAPrivateKey>(_privateKey));
    return _processData(decryptor, data);
  }

/*------------------------------Private methods-------------------------------*/

  SecureRandom _randomEngine() {
    final secureRandom = FortunaRandom();

    final seedSource = Random.secure();
    final seeds = <int>[];
    for (int i = 0; i < 32; i++) {
      seeds.add(seedSource.nextInt(255));
    }
    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));

    return secureRandom;
  }

  Uint8List _processData(AsymmetricBlockCipher engine, Uint8List data) {
    final numBlocks = data.length ~/ engine.inputBlockSize + ((data.length % engine.inputBlockSize != 0) ? 1 : 0);
    final output = Uint8List(numBlocks * engine.outputBlockSize);
    var inputOffset = 0;
    var outputOffset = 0;

    while (inputOffset < data.length) {
      final chunkSize = (inputOffset + engine.inputBlockSize <= data.length) ? engine.inputBlockSize : data.length - inputOffset;
      outputOffset += engine.processBlock(data, inputOffset, chunkSize, output, outputOffset);
      inputOffset += chunkSize;
    }

    return (output.length == outputOffset) ? output : output.sublist(0, outputOffset);
  }
}
