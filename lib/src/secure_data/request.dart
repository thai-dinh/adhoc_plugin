import 'package:cryptography/cryptography.dart';
import 'package:pointycastle/pointycastle.dart';


class Request {
  RSAPublicKey? publicKey;
  RSAPrivateKey? privateKey;
  SecretKey? sharedKey;
  int req;
  Object data;

  Request(this.req, this.data, {this.privateKey, this.publicKey});
}
