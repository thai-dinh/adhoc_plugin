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

// Constants for notification with regards to the technology
const WIFI_READY = WIFI;
const BLE_READY = BLE;

// Constants indicating the current connection state of the node
const STATE_NONE       = 100;        // No connection
const STATE_CONNECTED  = 101;        // Connected to a remote node
const STATE_CONNECTING = 102;        // Initiating a connection to a remote node
const STATE_LISTENING  = 103;        // Listening for incoming connections

// Constants for notifying discovery event
const DISCOVERY_START   = 104;       // Start discovery process
const DISCOVERY_END     = 105;       // End discovery process
const DEVICE_DISCOVERED = 106;       // Remote device discovered

// Constant for message event
const MESSAGE_RECEIVED = 107;        // Message received from peers

// Constants for connection event
const CONNECTION_PERFORMED   = 108;  // Connection performed
const CONNECTION_ABORTED     = 109;  // Connection aborted
const CONNECTION_EXCEPTION   = 110;  // Connection exception raised
const CONNECTION_INFORMATION = 111;  // Connection information

// Constants for device information event
const DEVICE_INFO_BLE     = 112;     // Device info (MAC + BLE UUID) recovered
const DEVICE_INFO_WIFI    = 113;     // Device info (MAC + Wi-Fi IP) recovered

// Constant for dealing with platform-specific side
const ANDROID_DISCOVERY  = 120;
const ANDROID_STATE      = 121;
const ANDROID_CONNECTION = 122;
const ANDROID_CHANGES    = 123;
