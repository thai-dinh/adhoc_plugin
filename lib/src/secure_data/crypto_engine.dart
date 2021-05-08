import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:adhoc_plugin/adhoc_plugin.dart';
import 'package:adhoc_plugin/src/secure_data/certificate.dart';
import 'package:adhoc_plugin/src/secure_data/reply.dart';
import 'package:adhoc_plugin/src/secure_data/request.dart';
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

    _sendPorts[ENCRYPTION].send(Request(publicKey, data));

    _stream.listen((reply) {
      if (reply.rep == ENCRYPTION) {
        completer.complete(reply.data);
      }
    });

    return completer.future;
  }

  Future<Uint8List> decrypt(Uint8List data) {
    Completer completer = new Completer<Uint8List>();

    _sendPorts[DECRYPTION].send(Request(_privateKey, data));

    _stream.listen((reply) {
      if (reply.rep == DECRYPTION) {
        completer.complete(reply.data);
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
  port.send(Reply(INITIALISATION, [ENCRYPTION ,_receivePort.sendPort]));

  _receivePort.listen((params) {
    final encryptor = OAEPEncoding(RSAEngine())
      ..init(true, PublicKeyParameter<RSAPublicKey>(params.key));
    Uint8List data = _processData(encryptor, params.data);
    port.send(Reply(ENCRYPTION, data));
  });
}

void processDecryption(SendPort port) {
  ReceivePort _receivePort = ReceivePort();
  port.send(Reply(INITIALISATION, [DECRYPTION ,_receivePort.sendPort]));

  _receivePort.listen((params) {
    final decryptor = OAEPEncoding(RSAEngine())
      ..init(false, PrivateKeyParameter<RSAPrivateKey>(params.key));
    Uint8List data = _processData(decryptor, params.data);
    port.send(Reply(DECRYPTION, data));
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
