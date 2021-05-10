import 'package:cryptography/cryptography.dart';
import 'package:pointycastle/pointycastle.dart';


class Request {
  RSAPublicKey publicKey;
  RSAPrivateKey privateKey;
  SecretKey sharedKey;
  Object data;

  Request(this.data, {this.privateKey, this.publicKey});
}
