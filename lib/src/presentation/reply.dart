import 'constants.dart';


/// Class representing the reply of the encryption/decryption isolate to a 
/// request of encryption/decryption.
class Reply {
  Object data;
  CryptoTask rep;

  /// Creates a [Reply] object.
  /// 
  /// The type of reply is defined by [rep], and the decrypted [data] is 
  /// returned.
  Reply(this.rep, this.data);
}
