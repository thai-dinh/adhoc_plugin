// Constant for the message digest (hash) algorithm
const DIGEST_IDENTIFIER = '0609608648016503040201';

// Constant for isolates
const NB_ISOLATE   = 2;           // Number of isolates for encryption/decryption

// Constants
const INITIALISATION = -1;  // Isolates initialisation
const ENCRYPTION     = 0;   // Encryption request and reply tag to send to an isolate
const DECRYPTION     = 1;   // Decryption request and reply tag to send to an isolate

// Constants
const SECRET_KEY  = 0;  // Secret key tag for cryptographic tasks
const SECRET_DATA = 1;  // Encrypted data tag for cryptographic tasks

// Constants
const LEADER = 0;  // Leader tag for group formation
const MEMBER = 1;  // Member tag for group formation

// Constants
const CERT_XCHG_BEGIN  = 300;     // Certificate exchange request
const CERT_XCHG_END    = 301;     // Certificate exchange reply
const ENCRYPTED_DATA   = 302;     // Data encrypted received or to send
const UNENCRYPTED_DATA = 303;     // Data unencrypted received or to send

// Constants for the secure group formation and management
const GROUP_REQUEST       = 310;  // Group creation initiation
const GROUP_REPLY         = 311;  // Group creation participation
const GROUP_FORMATION_REQ = 312;  // Group creation information exchange request
const GROUP_FORMATION_REP = 313;  // Group creation information exchange reply
const GROUP_JOIN          = 314;  // Group join request
const GROUP_LEAVE         = 315;  // Group leave request
const GROUP_ERROR         = 316;  // Group processing error
const GROUP_MESSAGE       = 317;  // Group message tag
