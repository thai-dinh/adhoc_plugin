import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:adhoc_plugin/src/presentation/certificate.dart';
import 'package:adhoc_plugin/src/presentation/constants.dart';
import 'package:adhoc_plugin/src/presentation/reply.dart';
import 'package:adhoc_plugin/src/presentation/request.dart';
import 'package:cryptography/cryptography.dart' as crypto;
import 'package:pointycastle/export.dart';

/// Class managing the encryption and decryption process.
class CryptoEngine {
  late RSAPublicKey publicKey;
  late RSAPrivateKey _privateKey;

  late ReceivePort _mainPort;
  late Stream<dynamic> _stream;
  late List<Isolate?> _isolates;
  late List<SendPort?> _sendPorts;

  /// Creates a [CryptoEngine] object.
  CryptoEngine() {
    final keys = generateRSAkeyPair();
    publicKey = keys.publicKey;
    _privateKey = keys.privateKey;
    _mainPort = ReceivePort();
    _stream = _mainPort.asBroadcastStream();
    _isolates = List.filled(NB_ISOLATE, null);
    _sendPorts = List.filled(NB_ISOLATE, null);
  }

/*------------------------------Getters & Setters-----------------------------*/

  /// RSA private key of this engine.
  set privateKey(RSAPrivateKey key) => _privateKey = key;

/*-------------------------------Public methods-------------------------------*/

  /// Initializes internal parameters.
  Future<void> initialize() async {
    _stream.listen((reply) {
      if (reply.rep == CryptoTask.initialisation) {
        _sendPorts[reply.data[0] as int] = reply.data[1] as SendPort;
      }
    });

    // Spawn the isolate for decryption and encryption
    _isolates[ENCRYPTION] = await Isolate.spawn(processEncryption, _mainPort.sendPort);
    _isolates[DECRYPTION] = await Isolate.spawn(processDecryption, _mainPort.sendPort);
  }

  /// Generates a pair of public and private key using the RSA algorithm.
  ///
  /// Returns a pair of [RSAPublicKey] and [RSAPrivateKey] key with a bit key
  /// length of 1024 bits.
  AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> generateRSAkeyPair() {
    // Bit key length
    var bitLength = 1024;

    // Create and initialize a RSA key generator
    final keyGen = RSAKeyGenerator()
      ..init(
        ParametersWithRandom(RSAKeyGeneratorParameters(BigInt.parse('65537'), bitLength, 64), 
        _random(),
      ),
    );

    // Generate the pair of key
    final pair = keyGen.generateKeyPair();
    final publicKey = pair.publicKey as RSAPublicKey;
    final privateKey = pair.privateKey as RSAPrivateKey;

    return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(publicKey, privateKey);
  }

  /// Encrypts the given data using a specified public key.
  ///
  /// The engine encrypts the [data] with the given cryptographic key.
  ///
  /// If [publicKey] of a remote node is set, then asymmetric encryption is
  /// performed.
  ///
  /// If [sharedKey] of a secure group is set, then symmetric encryption is
  /// performed.
  ///
  /// Returns the encrypted data as a list of dynamic objects.
  Future<List<dynamic>> encrypt(
    Uint8List data, {RSAPublicKey? publicKey, crypto.SecretKey? sharedKey}
  ) {
    Completer completer = Completer<List<dynamic>>();

    // Send request to encryption isolate
    if (publicKey != null) {
      _sendPorts[ENCRYPTION]!.send(Request(CryptoTask.encryption, data, publicKey: publicKey));
    } else {
      _sendPorts[ENCRYPTION]!.send(Request(CryptoTask.group_data, data, sharedKey: sharedKey));
    }

    // Listen to the reply of the encryption isolate
    _stream.listen((reply) {
      if (reply.rep == CryptoTask.encryption) {
        try {
          completer.complete(reply.data as List<dynamic>);
        } catch (exception) {}
      }
    });

    return completer.future as Future<List<dynamic>>;
  }

  /// Decrypts the given data using the node private key.
  ///
  /// The engine decrypts the [data] with a given cryptographic key.
  ///
  /// If [sharedKey] of a secure group is set, then symmetric decryption is
  /// performed. Otherwise, asymmetric decryption is performed with the private
  /// key of this node.
  ///
  /// Returns the decrypted data as a list of bytes [Uint8List].
  Future<Uint8List> decrypt(List data, {crypto.SecretKey? sharedKey}) {
    Completer completer = Completer<Uint8List>();

    // Send request to decryption isolate
    if (sharedKey == null) {
      _sendPorts[DECRYPTION]!.send(Request(CryptoTask.decryption, data, privateKey: _privateKey));
    } else {
      _sendPorts[DECRYPTION]!.send(Request(CryptoTask.group_data, data, sharedKey: sharedKey));
    }

    // Listen to the reply of the decryption isolate
    _stream.listen((reply) {
      if (reply.rep == CryptoTask.decryption) {
        try {
          completer.complete(Uint8List.fromList((reply.data as List<dynamic>).cast<int>()));
        } catch (exception) {}
      }
    });

    return completer.future as Future<Uint8List>;
  }

  /// Signs the given data with the private key of the node.
  ///
  /// The data to sign is specified by [data].
  ///
  /// Returns the digital signature of the data as a list of bytes [Uint8List].
  Uint8List sign(Uint8List data) {
    // Instantiate a RSASigner object with the desired digest algorithm
    final signer = RSASigner(SHA256Digest(), DIGEST_IDENTIFIER);

    // Set the verifier into sign mode
    signer.init(true, PrivateKeyParameter<RSAPrivateKey>(_privateKey));

    // Produce a digital signature of the given data
    return signer.generateSignature(data).bytes;
  }

  /// Verifies the given digital certificate with the given public key.
  ///
  /// The public [key] and digital [signature] is used to verify the digital
  /// [certificate].
  ///
  /// Returns true if the digital signature is valid for the given certificate,
  /// otherwise false.
  bool verify(Certificate certificate, Uint8List signature, RSAPublicKey key) {
    // Instantiate a RSASigner object with the desired digest algorithm
    final verifier = RSASigner(SHA256Digest(), DIGEST_IDENTIFIER);
    // Set the verifier into verify mode
    verifier.init(false, PublicKeyParameter<RSAPublicKey>(key));

    // Verify the signature
    return verifier.verifySignature(
      Utf8Encoder().convert(certificate.key.toString()),
      RSASignature(signature)
    );
  }

  /// Releases the ressource used by the isolates.
  void stop() {
    _mainPort.close();
    _isolates[ENCRYPTION]!.kill();
    _isolates[DECRYPTION]!.kill();
  }

/*------------------------------Private methods-------------------------------*/

  /// Returns a [SecureRandom] object;
  SecureRandom _random() {
    const ROLL = 32;

    final secureRandom = FortunaRandom();
    final seedSource = Random.secure();
    final seeds = List<int>.empty(growable: true);

    for (var i = 0; i < ROLL; i++) {
      seeds.add(seedSource.nextInt(255));
    }

    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));
    return secureRandom;
  }
}

/// High level method used by the encryption isolate.
///
/// The [port] is used to communicate with the isolate.
void processEncryption(SendPort port) {
  var _receivePort = ReceivePort();
  port.send(Reply(CryptoTask.initialisation, [ENCRYPTION, _receivePort.sendPort]));

  final algorithm = crypto.Chacha20.poly1305Aead();

  crypto.SecretKey secretKey;
  OAEPEncoding encryptor;
  var encryptedKey = Uint8List(0);

  _receivePort.listen((request) async {
    var req = request as Request;
    if (req.req == CryptoTask.encryption) {
      encryptor = OAEPEncoding(RSAEngine())
        ..init(true, PublicKeyParameter<RSAPublicKey>(request.publicKey!));

      secretKey = await algorithm.newSecretKey();

      encryptedKey = _processData(encryptor, Uint8List.fromList(await secretKey.extractBytes()));
    } else {
      secretKey = req.sharedKey!;
    }

    final secretBox = await algorithm.encrypt(
      request.data as Uint8List,
      secretKey: secretKey,
    );

    var reply = List<Uint8List>.filled(2, Uint8List.fromList([]));
    reply[SECRET_KEY] = encryptedKey;
    reply[SECRET_DATA] = secretBox.concatenation();

    port.send(Reply(CryptoTask.encryption, reply));
  });
}

/// High level method used by the decryption isolate.
///
/// The [port] is used to communicate with the isolate.
void processDecryption(SendPort port) {
  var _receivePort = ReceivePort();
  port.send(Reply(CryptoTask.initialisation, [DECRYPTION, _receivePort.sendPort]));

  final algorithm = crypto.Chacha20.poly1305Aead();

  crypto.SecretKey secretKey;
  OAEPEncoding decryptor;

  _receivePort.listen((request) async {
    var req = request as Request;
    var reply = request.data as List<dynamic>;

    if (req.req == CryptoTask.decryption) {
      decryptor = OAEPEncoding(RSAEngine())
        ..init(false, PrivateKeyParameter<RSAPrivateKey>(request.privateKey!));

      var secretKeyBytes = _processData(
        decryptor,
        Uint8List.fromList((reply[SECRET_KEY] as List<dynamic>).cast<int>())
      );

      secretKey = crypto.SecretKey(secretKeyBytes);
    } else {
      secretKey = req.sharedKey!;
    }

    var concatenation = Uint8List.fromList((reply[SECRET_DATA] as List<dynamic>).cast<int>());

    final secretBox = crypto.SecretBox(
      concatenation.sublist(12, concatenation.length - 16),
      nonce: concatenation.sublist(0, 12),
      mac: crypto.Mac(concatenation.sublist(concatenation.length - 16))
    );

    final decrypted = Uint8List.fromList(
      await algorithm.decrypt(secretBox, secretKey: secretKey),
    );

    port.send(Reply(CryptoTask.decryption, decrypted));
  });
}

/// Process the data give an encryption engine.
Uint8List _processData(AsymmetricBlockCipher engine, Uint8List data) {
  final numBlocks = data.length ~/ engine.inputBlockSize + 
    ((data.length % engine.inputBlockSize != 0) ? 1 : 0);

  final output = Uint8List(numBlocks * engine.outputBlockSize);
  var inputOffset = 0;
  var outputOffset = 0;

  while (inputOffset < data.length) {
    final chunkSize = (inputOffset + engine.inputBlockSize <= data.length)
        ? engine.inputBlockSize
        : data.length - inputOffset;

    outputOffset +=
        engine.processBlock(data, inputOffset, chunkSize, output, outputOffset);
    inputOffset += chunkSize;
  }

  return (output.length == outputOffset)
      ? output
      : output.sublist(0, outputOffset);
}
