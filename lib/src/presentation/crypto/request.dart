import 'package:cryptography/cryptography.dart';
import 'package:pointycastle/pointycastle.dart';

/// Class representing a request for encryption/decryption to the
/// encryption/decryption isolate.
class Request {
  final RSAPublicKey? publicKey;
  final RSAPrivateKey? privateKey;
  final SecretKey? sharedKey;
  final Object data;

  /// Creates a [Request] object.
  ///
  /// The decryption is done with regard to the given key. [privateKey] is used
  /// for decryption, [publicKey] for encryption, and [sharedKey] for group
  /// encryption/decryption.
  Request(this.data, {this.privateKey, this.publicKey, this.sharedKey});
}
