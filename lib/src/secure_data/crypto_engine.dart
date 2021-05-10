import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:adhoc_plugin/adhoc_plugin.dart';
import 'package:adhoc_plugin/src/secure_data/certificate.dart';
import 'package:adhoc_plugin/src/secure_data/reply.dart';
import 'package:adhoc_plugin/src/secure_data/request.dart';
import 'package:archive/archive_io.dart';
import 'package:cryptography/cryptography.dart' as Crypto;
import 'package:pointycastle/export.dart';


class CryptoEngine {
  RSAPublicKey _publicKey;
  RSAPrivateKey _privateKey;
  ReceivePort _mainPort;
  Stream<dynamic> _stream;
  List<Isolate> _isolates;
  List<SendPort> _sendPorts;

  CryptoEngine() {
    final keys = generateRSAkeyPair();
    this._publicKey = keys.publicKey;
    this._privateKey = keys.privateKey;
    this._mainPort = ReceivePort();
    this._stream = this._mainPort.asBroadcastStream();
    this._isolates = List.filled(NB_ISOLATE, null);
    this._sendPorts = List.filled(NB_ISOLATE, null);
    this._initialize();
  }

/*------------------------------Getters & Setters-----------------------------*/

  RSAPublicKey get publicKey => _publicKey;

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
    _sendPorts[ENCRYPTION].send(Request(compressed, publicKey: publicKey));

    _stream.listen((reply) {
      if (reply.rep == ENCRYPTION) {
        completer.complete(reply.data);
      }
    });

    return completer.future;
  }

  Future<Uint8List> decrypt(Uint8List data) {
    Completer completer = new Completer<Uint8List>();

    _sendPorts[DECRYPTION].send(Request(data, privateKey: _privateKey));

    _stream.listen((reply) {
      if (reply.rep == DECRYPTION) {
        Uint8List compressed = Uint8List.fromList(reply.data);
        List<int> decompressed = ZLibDecoder().decodeBytes(compressed);
        completer.complete(Uint8List.fromList(decompressed));
      }
    });

    return completer.future;
  }

  Uint8List sign(Uint8List data) {
    final signer = RSASigner(SHA256Digest(), '0609608648016503040201');
    signer.init(true, PrivateKeyParameter<RSAPrivateKey>(_privateKey));
    return signer.generateSignature(data).bytes;
  }

  bool verify(Certificate certificate, Uint8List signature, RSAPublicKey key) {
    final verifier = RSASigner(SHA256Digest(), '0609608648016503040201');
    verifier.init(false, PublicKeyParameter<RSAPublicKey>(key));
    certificate.signature = Uint8List(1);

    try {
      return verifier.verifySignature(Utf8Encoder().convert(certificate.toString()), RSASignature(signature));
    } on ArgumentError {
      return false;
    }
  }

  void stop() {
    _mainPort.close();
    _isolates[ENCRYPTION].kill();
    _isolates[DECRYPTION].kill();
  }

/*------------------------------Private methods-------------------------------*/

  void _initialize() async {
    _stream.listen((reply) {
      if (reply.rep == INITIALISATION) {
        _sendPorts[reply.data[0]] = reply.data[1];
      }
    });

    _isolates[ENCRYPTION] = await Isolate.spawn(processEncryption, _mainPort.sendPort);
    _isolates[DECRYPTION] = await Isolate.spawn(processDecryption, _mainPort.sendPort);
  }

  SecureRandom _random() {
    final secureRandom = FortunaRandom();
    final seedSource = Random.secure();
    final seeds = <int>[];
    for (int i = 0; i < 32; i++)
      seeds.add(seedSource.nextInt(255));
    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));
    return secureRandom;
  }
}

void processEncryption(SendPort port) {
  ReceivePort _receivePort = ReceivePort();
  port.send(Reply(INITIALISATION, [ENCRYPTION, _receivePort.sendPort]));

  _receivePort.listen((params) async {
    print('Begin encryption');
    Stopwatch stopwatch = Stopwatch()..start();

    final Crypto.AesCbc algorithm = Crypto.AesCbc.with128bits(macAlgorithm: Crypto.Hmac.sha256());
    final Crypto.SecretKey secretKey = await algorithm.newSecretKey();
    final Crypto.SecretBox secretBox = await algorithm.encrypt(
      params.data,
      secretKey: secretKey,
    );

    final OAEPEncoding encryptor = OAEPEncoding(RSAEngine())
      ..init(true, PublicKeyParameter<RSAPublicKey>(params.publicKey));
    Uint8List encryptedKey = _processData(encryptor, await secretKey.extractBytes());

    stopwatch.stop();
    print('End encryption');
    print('Execution time: ${stopwatch.elapsedMilliseconds} ms');

    List<List<int>> _secretBox = List.empty(growable: true);
    _secretBox.add(secretBox.cipherText);
    _secretBox.add(secretBox.nonce);
    _secretBox.add(secretBox.mac.bytes);
    List<dynamic> reply = List.filled(2, null);
    reply[SECRET_KEY] = encryptedKey;
    reply[SECRET_DATA] = _secretBox;
    Uint8List encrypted = Utf8Encoder().convert(JsonCodec().encode(reply));

    port.send(Reply(ENCRYPTION, encrypted));
  });
}

void processDecryption(SendPort port) {
  ReceivePort _receivePort = ReceivePort();
  port.send(Reply(INITIALISATION, [DECRYPTION, _receivePort.sendPort]));

  _receivePort.listen((params) async {
    print('Begin decryption');
    Stopwatch stopwatch = Stopwatch()..start();

    List<dynamic> reply = JsonCodec().decode(Utf8Decoder().convert(params.data));
    final OAEPEncoding decryptor = OAEPEncoding(RSAEngine())
      ..init(false, PrivateKeyParameter<RSAPrivateKey>(params.privateKey));
    Uint8List secretKey = _processData(decryptor, Uint8List.fromList((reply[SECRET_KEY] as List<dynamic>).cast<int>()));

    final Crypto.AesCbc algorithm = Crypto.AesCbc.with128bits(macAlgorithm: Crypto.Hmac.sha256());
    final Uint8List decrypted = await algorithm.decrypt(
      Crypto.SecretBox(
        (reply[SECRET_DATA][0] as List<dynamic>).cast<int>(),
        nonce: (reply[SECRET_DATA][1] as List<dynamic>).cast<int>(), 
        mac: Crypto.Mac((reply[SECRET_DATA][2] as List<dynamic>).cast<int>()),
      ),
      secretKey: Crypto.SecretKey(secretKey),
    );

    stopwatch.stop();
    print('End decryption');
    print('Execution time: ${stopwatch.elapsedMilliseconds} ms');

    port.send(Reply(DECRYPTION, decrypted));
  });
}

Uint8List _processData(AsymmetricBlockCipher engine, Uint8List data) {
  final int numBlocks = data.length ~/ engine.inputBlockSize + ((data.length % engine.inputBlockSize != 0) ? 1 : 0);
  final Uint8List output = Uint8List(numBlocks * engine.outputBlockSize);
  int inputOffset = 0;
  int outputOffset = 0;

  while (inputOffset < data.length) {
    final chunkSize = (inputOffset + engine.inputBlockSize <= data.length) ? engine.inputBlockSize : data.length - inputOffset;
    outputOffset += engine.processBlock(data, inputOffset, chunkSize, output, outputOffset);
    inputOffset += chunkSize;
  }

  return (output.length == outputOffset) ? output : output.sublist(0, outputOffset);
}
