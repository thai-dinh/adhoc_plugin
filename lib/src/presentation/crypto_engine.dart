import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart' as Crypto;
import 'package:pointycastle/export.dart';

import 'certificate.dart';
import 'constants.dart';
import 'reply.dart';
import 'request.dart';


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
    this.publicKey = keys.publicKey;
    this._privateKey = keys.privateKey;
    this._mainPort = ReceivePort();
    this._stream = this._mainPort.asBroadcastStream();
    this._isolates = List.filled(NB_ISOLATE, null);
    this._sendPorts = List.filled(NB_ISOLATE, null);
  }

/*------------------------------Getters & Setters-----------------------------*/

  /// RSA private key of this engine.
  set privateKey(RSAPrivateKey key) => this._privateKey = key;

/*-------------------------------Public methods-------------------------------*/

  /// Initializes internal parameters.
  Future<void> initialize() async {
    _stream.listen((reply) {
      if (reply.rep == CryptoTask.initialisation) {
        _sendPorts[reply.data[0]] = reply.data[1];
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
    int bitLength = 1024;

    // Create and initialize a RSA key generator
    final keyGen = RSAKeyGenerator()..init(ParametersWithRandom(
      RSAKeyGeneratorParameters(BigInt.parse('65537'), bitLength, 64), _random()
    ));

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
    Uint8List data, {RSAPublicKey? publicKey, Crypto.SecretKey? sharedKey}
  ) {
    Completer completer = new Completer<List<dynamic>>();

    // Send request to encryption isolate
    if (publicKey != null) {
      _sendPorts[ENCRYPTION]!.send(
        Request(CryptoTask.encryption, data, publicKey: publicKey)
      );
    } else {
      _sendPorts[ENCRYPTION]!.send(
        Request(CryptoTask.group_data, data, sharedKey: sharedKey)
      );
    }

    // Listen to the reply of the encryption isolate
    _stream.listen((reply) {
      if (reply.rep == CryptoTask.encryption) {
        try {
          completer.complete(reply.data as List<dynamic>);
        } catch (exception) { }
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
  Future<Uint8List> decrypt(List data, {Crypto.SecretKey? sharedKey}) {
    Completer completer = new Completer<Uint8List>();

    // Send request to decryption isolate
    if (sharedKey == null) {
      _sendPorts[DECRYPTION]!.send(
        Request(CryptoTask.decryption, data, privateKey: _privateKey)
      );
    } else {
      _sendPorts[DECRYPTION]!.send(
        Request(CryptoTask.group_data, data, sharedKey: sharedKey)
      );
    }

    // Listen to the reply of the decryption isolate
    _stream.listen((reply) {
      if (reply.rep == CryptoTask.decryption) {
        try {
          completer.complete(Uint8List.fromList(reply.data));
        } catch (exception) { }
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
    final RSASigner signer = RSASigner(SHA256Digest(), DIGEST_IDENTIFIER);

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
    final RSASigner verifier = RSASigner(SHA256Digest(), DIGEST_IDENTIFIER);
    // Set the verifier into verify mode
    verifier.init(false, PublicKeyParameter<RSAPublicKey>(key));

    try {
      // Verify the signature
      return verifier.verifySignature(
        Utf8Encoder().convert(certificate.key.toString()), RSASignature(signature)
      );
    } on ArgumentError {
      return false;
    }
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

    final FortunaRandom secureRandom = FortunaRandom();
    final Random seedSource = Random.secure();
    final List<int> seeds = List.empty(growable: true);

    for (int i = 0; i < ROLL; i++)
      seeds.add(seedSource.nextInt(255));

    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));
    return secureRandom;
  }
}


/// High level method used by the encryption isolate.
/// 
/// The [port] is used to communicate with the isolate. 
void processEncryption(SendPort port) {
  ReceivePort _receivePort = ReceivePort();
  port.send(
    Reply(CryptoTask.initialisation, [ENCRYPTION ,_receivePort.sendPort])
  );

  final Crypto.Chacha20 algorithm = Crypto.Chacha20(
    macAlgorithm: Crypto.Hmac.sha256()
  );

  Crypto.SecretKey secretKey;
  OAEPEncoding encryptor;
  Uint8List? encryptedKey;

  _receivePort.listen((request) async {
    Request req = request as Request;
    if (req.req == CryptoTask.encryption) {
      encryptor = OAEPEncoding(RSAEngine())..init(
        true, PublicKeyParameter<RSAPublicKey>(request.publicKey!)
      );

      secretKey = await algorithm.newSecretKey();

      encryptedKey = _processData(
        encryptor, Uint8List.fromList(await secretKey.extractBytes())
      );
    } else {
      secretKey = req.sharedKey!;
    }

    final Crypto.SecretBox secretBox = await algorithm.encrypt(
      request.data as Uint8List,
      secretKey: secretKey,
    );

    List<List<int>> encryptedData = List.empty(growable: true);
    encryptedData.add(secretBox.cipherText);
    encryptedData.add(secretBox.nonce);
    encryptedData.add(secretBox.mac.bytes);

    print(secretBox.mac.bytes);

    List<dynamic> reply = List.filled(2, null);
    reply[SECRET_KEY] = encryptedKey;
    reply[SECRET_DATA] = encryptedData;

    port.send(Reply(CryptoTask.encryption, reply));
  });
}


/// High level method used by the decryption isolate.
/// 
/// The [port] is used to communicate with the isolate. 
void processDecryption(SendPort port) {
  ReceivePort _receivePort = ReceivePort();
  port.send(Reply(CryptoTask.initialisation, [DECRYPTION ,_receivePort.sendPort]));

  final Crypto.Chacha20 algorithm = Crypto.Chacha20(
    macAlgorithm: Crypto.Hmac.sha256()
  );

  Crypto.SecretKey secretKey;
  OAEPEncoding decryptor;

  _receivePort.listen((request) async {
    Request req = request as Request;
    List<dynamic> reply = request.data as List<dynamic>;

    if (req.req == CryptoTask.decryption) {
      decryptor = OAEPEncoding(RSAEngine())..init(
        false, PrivateKeyParameter<RSAPrivateKey>(request.privateKey!)
      );

      Uint8List secretKeyBytes = _processData(
        decryptor, Uint8List.fromList(
          (reply[SECRET_KEY] as List<dynamic>).cast<int>()
        )
      );

      secretKey = Crypto.SecretKey(secretKeyBytes);
    } else {
      secretKey = req.sharedKey!;
    }

    print(reply[SECRET_DATA][2]);

    final Uint8List decrypted = Uint8List.fromList(
      await algorithm.decrypt(
        Crypto.SecretBox(
          (reply[SECRET_DATA][0] as List<dynamic>).cast<int>(),
          nonce: (reply[SECRET_DATA][1] as List<dynamic>).cast<int>(), 
          mac: Crypto.Mac((reply[SECRET_DATA][2] as List<dynamic>).cast<int>()),
        ),
        secretKey: secretKey,
      ),
    );

    port.send(Reply(CryptoTask.decryption, decrypted));
  });
}


/// Process the data give an encryption engine.
Uint8List _processData(AsymmetricBlockCipher engine, Uint8List data) {
  final int numBlocks = data.length ~/ engine.inputBlockSize 
    + ((data.length % engine.inputBlockSize != 0) ? 1 : 0);

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
