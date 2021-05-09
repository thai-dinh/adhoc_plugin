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

    print('Begin compression');
    Stopwatch stopwatch = Stopwatch()..start();
    List<int> compressed = ZLibEncoder().encode(data);
    stopwatch.stop();
    print('End compression');

    String message = 'Execution time: ';
    print(message + '${stopwatch.elapsedMilliseconds} ms');

    _sendPorts[ENCRYPTION].send(Request(publicKey, compressed));

    _stream.listen((reply) {
      if (reply.rep == ENCRYPTION) {
        completer.complete(reply.data);
      }
    });

    return completer.future;
  }

  Future<Uint8List> decrypt(Uint8List data) {
    Completer completer = new Completer<Uint8List>();
    int received = 0;
    List<Uint8List> _data = List.filled(2, null);

    _sendPorts[DECRYPTION].send(Request(_privateKey, data.sublist(0, data.length~/2)));
    _sendPorts[DECRYPTION+1].send(Request(_privateKey, data.sublist(data.length~/2)));

    _stream.listen((reply) {
      if (reply.rep == 1) {
        _data[0] = reply.data;
        received++;
      } else if (reply.rep == 2) {
        _data[1] = reply.data;
        received++;
      }

      if (received == 2) {
        print('Begin decompression');
        Stopwatch stopwatch = Stopwatch()..start();
        Uint8List compressed = Uint8List.fromList(_data[0] + _data[1]);
        List<int> decompressed = ZLibDecoder().decodeBytes(compressed);
        stopwatch.stop();
        print('End decompression');

        String message = 'Execution time: ';
        print(message + '${stopwatch.elapsedMilliseconds} ms');

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

    _isolates[0] = await Isolate.spawn(processEncryption, _mainPort.sendPort);
    _isolates[1] = await Isolate.spawn(processDecryption1, _mainPort.sendPort);
    _isolates[2] = await Isolate.spawn(processDecryption2, _mainPort.sendPort);
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
  port.send(Reply(INITIALISATION, [0, _receivePort.sendPort]));

  _receivePort.listen((params) {
    print('Begin encryption');
    Stopwatch stopwatch = Stopwatch()..start();

    final encryptor = OAEPEncoding(RSAEngine())
      ..init(true, PublicKeyParameter<RSAPublicKey>(params.key));
    Uint8List data = _processData(encryptor, params.data);

    stopwatch.stop();
    print('End encryption');
    print('Execution time: ${stopwatch.elapsedMilliseconds} ms');

    port.send(Reply(0, data));
  });
}

void processDecryption1(SendPort port) {
  ReceivePort _receivePort = ReceivePort();
  port.send(Reply(INITIALISATION, [1, _receivePort.sendPort]));

  _receivePort.listen((params) {
    print('Begin decryption 1');
    Stopwatch stopwatch = Stopwatch()..start();

    final decryptor = OAEPEncoding(RSAEngine())
      ..init(false, PrivateKeyParameter<RSAPrivateKey>(params.key));
    Uint8List data = _processData(decryptor, params.data);

    stopwatch.stop();
    print('End decryption 1');
    print('Execution time: ${stopwatch.elapsedMilliseconds} ms');

    port.send(Reply(1, data));
  });
}

void processDecryption2(SendPort port) {
  ReceivePort _receivePort = ReceivePort();
  port.send(Reply(INITIALISATION, [2, _receivePort.sendPort]));

  _receivePort.listen((params) {
    print('Begin decryption 2');
    Stopwatch stopwatch = Stopwatch()..start();

    final decryptor = OAEPEncoding(RSAEngine())
      ..init(false, PrivateKeyParameter<RSAPrivateKey>(params.key));
    Uint8List data = _processData(decryptor, params.data);

    stopwatch.stop();
    print('End decryption 2');
    print('Execution time: ${stopwatch.elapsedMilliseconds} ms');

    port.send(Reply(2, data));
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
