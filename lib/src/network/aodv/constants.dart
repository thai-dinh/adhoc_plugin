// Constants for hop counts and TTL values;
const TTL = [100, 50, 25, 10, 5, 3];
const INIT_HOP_COUNT = 0;
const RREQ_RETRIES = 5;
const MAX_SINT_VAL = 4294967296;  // Max signed integer value


// Sequence Numbers
const MIN_VALID_SEQ_NUM = 0;
const MAX_VALID_SEQ_NUM = MAX_SINT_VAL;
const UNKNOWN_SEQUENCE_NUMBER = 0;
const FIRST_SEQUENCE_NUMBER = 1;

// Constants for network purposes
const NET_TRANVERSAL_TIME = 2800;
const EXPIRED_TABLE = 10000;
const EXPIRED_TIME = EXPIRED_TABLE * 2;
const NO_LIFE_TIME = -1;
const LIFE_TIME = EXPIRED_TIME; // Life time of a route

// Constants for displaying the routing table
const DELAY  = 60000;
const PERIOD = DELAY;

// AODV PDU types
const RREQ = 1;
const RREP = 2;
const RERR = 3;
const RREP_GRATUITOUS = 4;
const DATA = 5;
