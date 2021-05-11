import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:adhoc_plugin/adhoc_plugin.dart';
import 'package:adhoc_plugin/src/datalink/utils/utils.dart' as Utils;
import 'package:adhoc_plugin/src/secure_data/certificate.dart';
import 'package:adhoc_plugin/src/secure_data/reply.dart';
import 'package:adhoc_plugin/src/secure_data/request.dart';
import 'package:archive/archive_io.dart';
import 'package:cryptography/cryptography.dart' as Crypto;
import 'package:pointycastle/export.dart';


class CryptoEngine {
  RSAPublicKey? _publicKey;
  RSAPrivateKey? _privateKey;
  late ReceivePort _mainPort;
  late Stream<dynamic> _stream;
  late Isolate _isolate;
  SendPort? _sendPort;

  CryptoEngine() {
    final keys = generateRSAkeyPair();
    this._publicKey = keys.publicKey;
    this._privateKey = keys.privateKey;
    this._mainPort = ReceivePort();
    this._stream = this._mainPort.asBroadcastStream();
    this._initialize();
  }

/*------------------------------Getters & Setters-----------------------------*/

  RSAPublicKey? get publicKey => _publicKey;

/*-------------------------------Public methods-------------------------------*/

  AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> generateRSAkeyPair() {
    int bitLength = 2048;
    final keyGen = RSAKeyGenerator()..init(ParametersWithRandom(
      RSAKeyGeneratorParameters(BigInt.parse('65537'), bitLength, 64), 
      _random()
    ));

    final pair = keyGen.generateKeyPair();
    final publicKey = pair.publicKey as RSAPublicKey;
    final privateKey = pair.privateKey as RSAPrivateKey;

    return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(publicKey, privateKey);
  }

  Future<Uint8List> encrypt(Uint8List data, RSAPublicKey publicKey) {
    Completer completer = new Completer<Uint8List>();

    List<int> compressed = ZLibEncoder().encode(data);
    _sendPort!.send(Request(ENCRYPTION, compressed, publicKey: publicKey));

    _stream.listen((reply) {
      if (reply.rep == ENCRYPTION) {
        completer.complete(reply.data);
      }
    });

    return completer.future as Future<Uint8List>;
  }

  Future<Uint8List> decrypt(Uint8List data) {
    Completer completer = new Completer<Uint8List>();

    _sendPort!.send(Request(DECRYPTION, data, privateKey: _privateKey));

    _stream.listen((reply) {
      if (reply.rep == DECRYPTION) {
        Uint8List compressed = Uint8List.fromList(reply.data);
        List<int> decompressed = ZLibDecoder().decodeBytes(compressed);
        completer.complete(Uint8List.fromList(decompressed));
      }
    });

    return completer.future as Future<Uint8List>;
  }

  Uint8List sign(Uint8List data) {
    final RSASigner signer = RSASigner(SHA256Digest(), DIGEST_IDENTIFIER);
    signer.init(true, PrivateKeyParameter<RSAPrivateKey>(_privateKey!));
    return signer.generateSignature(data).bytes;
  }

  bool verify(Certificate certificate, Uint8List signature, RSAPublicKey key) {
    final RSASigner verifier = RSASigner(SHA256Digest(), DIGEST_IDENTIFIER);
    verifier.init(false, PublicKeyParameter<RSAPublicKey>(key));
    certificate.signature = Uint8List(1);

    try {
      return verifier.verifySignature(
        Utf8Encoder().convert(certificate.toString()), RSASignature(signature)
      );
    } on ArgumentError {
      return false;
    }
  }

  void stop() {
    _mainPort.close();
    _isolate.kill();
  }

/*------------------------------Private methods-------------------------------*/

  void _initialize() async {
    _stream.listen((reply) {
      if (reply.rep == INITIALISATION) {
        _sendPort = reply.data;
      }
    });

    _isolate = await Isolate.spawn(_processCryptoTask, _mainPort.sendPort);
  }

  SecureRandom _random() {
    const ROLL = 32;

    final FortunaRandom secureRandom = FortunaRandom();
    final Random seedSource = Random.secure();
    final List<int> seeds = List.empty(growable: true);

    for (int i = 0; i < ROLL; i++)
      seeds.add(seedSource.nextInt(255));

    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));
    return secureRandom;
  }
}

void _processCryptoTask(SendPort port) {
  ReceivePort _receivePort = ReceivePort();
  port.send(Reply(INITIALISATION, _receivePort.sendPort));

  _receivePort.listen((request) async {
    if (request.req == ENCRYPTION) {
      port.send(Reply(ENCRYPTION, await _encrypt(request)));
    } else {
      port.send(Reply(DECRYPTION, await _decrypt(request)));
    }
  });
}

Future<Uint8List> _encrypt(Request request) async {
  final Crypto.AesCbc algorithm = Crypto.AesCbc.with128bits(
    macAlgorithm: Crypto.Hmac.sha256()
  );

  Stopwatch watch = Stopwatch()..start();
  Utils.log('[CryptoEngine]', 'Start encryption');

  final Crypto.SecretKey secretKey = await algorithm.newSecretKey();
  final Crypto.SecretBox secretBox = await algorithm.encrypt(
    request.data as List<int>,
    secretKey: secretKey,
  );

  final OAEPEncoding encryptor = OAEPEncoding(RSAEngine())
    ..init(true, PublicKeyParameter<RSAPublicKey>(request.publicKey!));
  Uint8List encryptedKey = _processData(encryptor, Uint8List.fromList(await secretKey.extractBytes()));

  watch.stop();
  Utils.log('[CryptoEngine]', 'End encryption ${watch.elapsedMilliseconds}');

  List<List<int>> encryptedData = List.empty(growable: true);
  encryptedData.add(secretBox.cipherText);
  encryptedData.add(secretBox.nonce);
  encryptedData.add(secretBox.mac.bytes);

  List<dynamic> reply = List.filled(2, null);
  reply[SECRET_KEY] = encryptedKey;
  reply[SECRET_DATA] = encryptedData;

  return Utf8Encoder().convert(JsonCodec().encode(reply));
}

Future<Uint8List> _decrypt(Request request) async {
  Stopwatch watch = Stopwatch()..start();
  Utils.log('[CryptoEngine]', 'Start decryption');

  List<dynamic> reply = JsonCodec().decode(Utf8Decoder().convert(request.data as List<int>));
  final OAEPEncoding decryptor = OAEPEncoding(RSAEngine())
    ..init(false, PrivateKeyParameter<RSAPrivateKey>(request.privateKey!));

  Uint8List secretKey = _processData(
    decryptor, Uint8List.fromList((reply[SECRET_KEY] as List<dynamic>).cast<int>())
  );

  final Crypto.AesCbc algorithm = Crypto.AesCbc.with128bits(
    macAlgorithm: Crypto.Hmac.sha256()
  );

  final Uint8List decrypted = Uint8List.fromList(
    await algorithm.decrypt(
      Crypto.SecretBox(
        (reply[SECRET_DATA][0] as List<dynamic>).cast<int>(),
        nonce: (reply[SECRET_DATA][1] as List<dynamic>).cast<int>(), 
        mac: Crypto.Mac((reply[SECRET_DATA][2] as List<dynamic>).cast<int>()),
      ),
      secretKey: Crypto.SecretKey(secretKey),
    ),
  );

  watch.stop();
  Utils.log('[CryptoEngine]', 'End decryption ${watch.elapsedMilliseconds}');

  return decrypted;
}

Uint8List _processData(AsymmetricBlockCipher engine, Uint8List data) {
  final int numBlocks = data.length ~/ engine.inputBlockSize + ((data.length % engine.inputBlockSize != 0) ? 1 : 0);
  final Uint8List output = Uint8List(numBlocks * engine.outputBlockSize);
  int inputOffset = 0;
  int outputOffset = 0;

  while (inputOffset < data.length) {
    final int chunkSize = (inputOffset + engine.inputBlockSize <= data.length) ? 
      engine.inputBlockSize : data.length - inputOffset;

    outputOffset += engine.processBlock(data, inputOffset, chunkSize, output, outputOffset);
    inputOffset += chunkSize;
  }

  return (output.length == outputOffset) ? output : output.sublist(0, outputOffset);
}
