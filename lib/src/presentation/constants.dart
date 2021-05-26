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

// Constants
const LEADER = 0;  // Leader tag for group formation
const MEMBER = 1;  // Member tag for group formation

// Constants for the group key agreement protocol
const FORMATION = 30;
const JOIN = 31;
const LEAVE = 32;
const REQUEST = 33;
const REPLY = 34;

// Constants for the certificate management
const ENCRYPTED_DATA   = 300;     // Data encrypted received or to send
const UNENCRYPTED_DATA = 301;     // Data unencrypted received or to send
const CERT_XCHG_REQ    = 302;     // Certificate exchange request
const CERT_XCHG_REP    = 303;     // Certificate exchange reply
const CERT_REQ         = 304;     // Request certificate
const CERT_REP         = 305;     // Reply to certificate request
const CERT_REVOCATION  = 306;     // Certificate revocation notification

// Constants for the secure group formation and management
const GROUP_REQUEST       = 310;  // Group creation initiation
const GROUP_REPLY         = 311;  // Group creation participation
const GROUP_FORMATION_REQ = 312;  // Group creation information exchange request
const GROUP_FORMATION_REP = 313;  // Group creation information exchange reply
const GROUP_JOIN_REQ      = 314;  // Group join request
const GROUP_JOIN_REP      = 315;  // Group join reply
const GROUP_LEAVE_REQ     = 316;  // Group leave request
const GROUP_LEAVE_REP     = 317;  // Group leave reply
const GROUP_ERROR         = 318;  // Group processing error
const GROUP_MESSAGE       = 319;  // Group message tag
