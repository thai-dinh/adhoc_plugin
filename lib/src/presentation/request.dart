import 'package:adhoc_plugin/src/presentation/constants.dart';
import 'package:cryptography/cryptography.dart';
import 'package:pointycastle/pointycastle.dart';

/// Class representing a request for encryption/decryption to the
/// encryption/decryption isolate.
class Request {
  RSAPublicKey? publicKey;
  RSAPrivateKey? privateKey;
  SecretKey? sharedKey;
  CryptoTask req;
  Object data;

  /// Creates a [Request] object.
  ///
  /// The type of encryption of the [data] is defined by [req].
  ///
  /// Depending on the type, the cryptographic key needs to be set: [privateKey],
  /// for decryption, [publicKey] for encryption, and [sharedKey] for group
  /// encryption/decryption.
  Request(this.req, this.data, {this.privateKey, this.publicKey, this.sharedKey});
}
