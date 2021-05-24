// GATT service of Bluetooth Low Energy
/// Ad hoc service UUID
const SERVICE_UUID        = '00000001-0000-1000-8000-00805f9b34fb';
/// Ad hoc characteristic UUID
const CHARACTERISTIC_UUID = '00000002-0000-1000-8000-00805f9b34fb';
/// Prefix of BLE UUID
const BLUETOOTHLE_UUID    = 'e0917680-d427-11e4-8830-';


// Maximum Transmission Unit (Bluetooth Low Energy)
/// Minimum MTU allowed (BLE)
const MIN_MTU = 20;
/// Maximum MTU allowed (BLE)
const MAX_MTU = 500;


// Data fragmentation
/// TAG indicating the end of fragmentation
const MESSAGE_END  = 0;
/// TAG indicating data part of fragmentation
const MESSAGE_FRAG = 1;


// Miscellaneous constants
/// Maximum value of a integer (8 bytes)
const UINT8_SIZE = 256;
/// Discovery duration (milliseconds)
const DISCOVERY_TIME = 10000;
/// Back off time constant (lower bound)
const LOW  = 1500;
/// Back off time constant (higher bound)
const HIGH = 2500;
/// Wi-Fi type
const WIFI = 0;
/// Bluetooth Low Energy type
const BLE  = 1;
/// Wi-Fi technology ready
const WIFI_READY = WIFI;
/// Bluetooth Low Energy technology ready
const BLE_READY = BLE;
/// Server TAG
const SERVER = WIFI;
/// Client TAG
const CLIENT = BLE;


// Constants indicating the current connection state of the node
/// No connection state
const STATE_NONE              = 100;
/// Connected to a remote node
const STATE_CONNECTED         = 101;
/// Initiating a connection to a remote node
const STATE_CONNECTING        = 102;
/// Listening for incoming connections
const STATE_LISTENING         = 103;
/// Start discovery process
const DISCOVERY_START         = 104;
/// End discovery process
const DISCOVERY_END           = 105;
/// Remote device discovered
const DEVICE_DISCOVERED       = 106;
/// Message received from peers
const MESSAGE_RECEIVED        = 107;
/// Connection performed
const CONNECTION_PERFORMED    = 108;
/// Connection aborted
const CONNECTION_ABORTED      = 109;
/// Connection exception raised
const CONNECTION_EXCEPTION    = 110;
/// Connection information
const CONNECTION_INFORMATION  = 111;
/// Device info (MAC + BLE UUID) recovered
const DEVICE_INFO_BLE         = 112;
/// Device info (MAC + Wi-Fi IP) recovered
const DEVICE_INFO_WIFI        = 113;
/// Discovery process finished
const ANDROID_DISCOVERY       = 120;
/// Local adapter state (on/off)
const ANDROID_STATE           = 121;
/// Wi-Fi Direct connection information
const ANDROID_CONNECTION      = 122;
/// Device name and/or MAC address changes
const ANDROID_CHANGES         = 123;
/// Ble pairing request
const ANDROID_BOND            = 124;
/// Data written or read from characteristic
const ANDROID_DATA            = 125;
