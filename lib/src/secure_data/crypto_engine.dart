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
  Isolate _isolate;
  ReceivePort _receivePort;
  SendPort _sendPort;
  Stream<dynamic> _stream;
  RSAPublicKey _publicKey;
  RSAPrivateKey _privateKey;

  CryptoEngine() {
    final keys = generateRSAkeyPair();
    this._publicKey = keys.publicKey;
    this._privateKey = keys.privateKey;
    this._receivePort = ReceivePort();
    this._stream = this._receivePort.asBroadcastStream();
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

  Future<Uint8List> encrypt(Uint8List data, RSAPublicKey key) {
    Completer completer = new Completer<Uint8List>();

    _sendPort.send(Request(ENCRYPT, key, data));

    _stream.listen((reply) {
      if (reply is Reply && reply.rep == ENCRYPT) {
        completer.complete(reply.data);
      }
    });

    return completer.future;
  }

  Future<Uint8List> decrypt(Uint8List data) {
    Completer completer = new Completer<Uint8List>();

    _sendPort.send(Request(DECRYPT, _privateKey, data));

    _stream.listen((reply) {
      if (reply is Reply && reply.rep == DECRYPT) {
        completer.complete(reply.data);
      }
    });

    return completer.future;
  }

  Future<Uint8List> sign(Uint8List data) {
    Completer completer = new Completer<Uint8List>();

    _sendPort.send(Request(SIGN, _privateKey, data));

    _stream.listen((reply) {
      if (reply is Reply && reply.rep == SIGN) {
        completer.complete(reply.data);
      }
    });

    return completer.future;
  }

  Future<bool> verify(Certificate certificate, Uint8List signature, RSAPublicKey key) {
    Completer completer = new Completer<bool>();

    _sendPort.send(Request(VERIFY, key, [certificate, signature]));

    _stream.listen((reply) {
      if (reply is Reply && reply.rep == VERIFY) {
        completer.complete(reply.data);
      }
    });

    return completer.future;
  }

  void stop() {
    _receivePort.close();
    _isolate.kill();
  }

/*------------------------------Private methods-------------------------------*/

  void _initialize() async {
    _stream.listen((reply) {
      if (reply is SendPort) {
        _sendPort = reply;
      }
    });

    _isolate = await Isolate.spawn(processCryptoTask, _receivePort.sendPort);
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

void processCryptoTask(SendPort port) {
  ReceivePort _receivePort = ReceivePort();
  port.send(_receivePort.sendPort);

  _receivePort.listen((request) {
    Request _request = request as Request;
    switch (_request.req) {
      case ENCRYPT:
        final encryptor = OAEPEncoding(RSAEngine())
          ..init(true, PublicKeyParameter<RSAPublicKey>(_request.key));
        Uint8List data = _processData(encryptor, _request.data);
        port.send(Reply(ENCRYPT, data));
        break;

      case DECRYPT:
        final decryptor = OAEPEncoding(RSAEngine())
          ..init(false, PrivateKeyParameter<RSAPrivateKey>(_request.key));
        Uint8List data = _processData(decryptor, _request.data);
        port.send(Reply(DECRYPT, data));
        break;

      case SIGN:
        final signer = RSASigner(SHA256Digest(), '0609608648016503040201');
        signer.init(true, PrivateKeyParameter<RSAPrivateKey>(_request.key));
        Uint8List result = signer.generateSignature(_request.data).bytes;
        port.send(Reply(SIGN, result));
        break;

      case VERIFY:
        final verifier = RSASigner(SHA256Digest(), '0609608648016503040201');
        verifier.init(false, PublicKeyParameter<RSAPublicKey>(_request.key));
        Certificate certificate = (_request.data as List)[0];
        Uint8List signature = (_request.data as List)[1];
        certificate.signature = Uint8List(1);

        try {
          bool result = verifier.verifySignature(Utf8Encoder().convert(certificate.toString()), RSASignature(signature));
          port.send(Reply(VERIFY, result));
        } on ArgumentError {
          port.send(Reply(VERIFY, false));
        }
        break;

      default:
    }
  });
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
