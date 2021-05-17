// Constants for the GATT service of Bluetooth Low Energy
const SERVICE_UUID        = '00000001-0000-1000-8000-00805f9b34fb'; // Service UUID
const CHARACTERISTIC_UUID = '00000002-0000-1000-8000-00805f9b34fb'; // Characteristic UUID
const BLUETOOTHLE_UUID    = 'e0917680-d427-11e4-8830-';             // Prefix of BLE UUID

// Constants for the maximum transmission unit (Bluetooth Low Energy)
const MIN_MTU = 20;
const MAX_MTU = 500;

// Constants for the message fragmentation
const MESSAGE_END   = 0;
const MESSAGE_BEGIN = 1;

// Constant for the size of a byte
const UINT8_SIZE = 256;

// Constant setting the time of the discovery process in milliseconds
const DISCOVERY_TIME = 10000;

// Constants for computing the back off time
const LOW  = 1500;
const HIGH = 2500;

// Constants for type of technology
const WIFI = 0;
const BLE  = 1;

// Constants indicating the current connection state of the node
const STATE_NONE       = 0;        // No connection
const STATE_CONNECTED  = 1;        // Connected to a remote node
const STATE_CONNECTING = 2;        // Initiating a connection to a remote node
const STATE_LISTENING  = 3;        // Listening for incoming connections

// Constants for notifying discovery event
const DISCOVERY_START   = 4;       // Start discovery process
const DISCOVERY_END     = 5;       // End discovery process
const DEVICE_DISCOVERED = 6;       // Remote device discovered

// Constant for message event
const MESSAGE_RECEIVED = 7;        // Message received from peers

// Constants for connection event
const CONNECTION_PERFORMED = 8;    // Connection performed
const CONNECTION_ABORTED   = 9;    // Connection aborted
const CONNECTION_EXCEPTION = 10;   // Connection exception raised
