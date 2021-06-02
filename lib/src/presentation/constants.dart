// Constant for the message digest (hash) algorithm
const DIGEST_IDENTIFIER = '0609608648016503040201';

// Constant for isolates
const NB_ISOLATE = 2; // Number of isolates for encryption/decryption

// Constants
const INITIALISATION = -1;  // Isolates initialisation
const ENCRYPTION = 0;       // Encryption request and reply tag to send to an isolate
const DECRYPTION = 1;       // Decryption request and reply tag to send to an isolate

// Constants
const SECRET_KEY = 0;   // Secret key tag for cryptographic tasks
const SECRET_DATA = 1;  // Encrypted data tag for cryptographic tasks

// Constants for the certificate management
const ENCRYPTED_DATA    = 300;     // Data encrypted received or to send
const UNENCRYPTED_DATA  = 301;     // Data unencrypted received or to send
const CERT_EXCHANGE     = 302;     // Certificate exchange request
const CERT_REQ          = 304;     // Request certificate
const CERT_REP          = 305;     // Reply to certificate request
const CERT_REVOCATION   = 306;     // Certificate revocation notification
const GROUP_STATUS      = 307;     // Group status notification
const GROUP_LEAVE       = 308;     // Group left notification
const GROUP_JOIN        = 309;     // Group join notification
const GROUP_KEY_UPDATED = 310;     // Group key update notification

enum CryptoTask {
  /// Isoalte initialisation 
  initialisation,

  /// Encryption tag
  encryption,

  /// Decryption tag
  decryption,

  /// Group encryption & decryption tag
  group_data,
}

enum SecureGroup {
  /// Group key computation
  key,

  /// Group formation initiation
  init,

  /// Group formation reply
  reply,

  /// List of group member's label
  list,

  /// Public Diffie-Hellman share received
  share,

  /// Group join notification
  join,

  /// Group join request to leader
  join_req,

  /// Group join reply of leader
  join_rep,

  /// Group leave notification
  leave,

  /// Group data
  data
}
