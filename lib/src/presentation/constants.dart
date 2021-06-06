// Constant for the message digest (hash) algorithm
const DIGEST_IDENTIFIER = '0609608648016503040201';

// Constant for isolates
const NB_ISOLATE = 2; // Number of isolates for encryption/decryption

// Constants
const INITIALISATION = -1; // Isolates initialisation
const ENCRYPTION = 0; // Encryption request and reply tag to send to an isolate
const DECRYPTION = 1; // Decryption request and reply tag to send to an isolate

// Constants
const SECRET_KEY = 0; // Secret key tag for cryptographic tasks
const SECRET_DATA = 1; // Encrypted data tag for cryptographic tasks

// Constants for the certificate management
const ENCRYPTED_DATA = 300; // Data encrypted received or to send
const UNENCRYPTED_DATA = 301; // Data unencrypted received or to send
const CERT_EXCHANGE = 302; // Certificate exchange request
const CERT_REQ = 304; // Request certificate
const CERT_REP = 305; // Reply to certificate request
const CERT_REVOCATION = 306; // Certificate revocation notification

// Constants for group management
const GROUP_STATUS = 307;
const GROUP_LEAVE = 308;
const GROUP_JOIN = 309;
const GROUP_KEY = 310;
const GROUP_INIT = 311;
const GROUP_REPLY = 312;
const GROUP_LIST = 313;
const GROUP_SHARE = 314;
const GROUP_JOIN_REQ = 315;
const GROUP_JOIN_REP = 316;
const GROUP_DATA = 318;
