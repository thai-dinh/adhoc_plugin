class BleUtils {
  static const SERVICE_UUID = '00000001-0000-1000-8000-00805f9b34fb';
  static const CHARACTERISTIC_UUID = '00000002-0000-1000-8000-00805f9b34fb';

  static const STATE_DISCONNECTED = 0;
  static const STATE_CONNECTED = 1;

  static const MIN_MTU = 20;
  static const MAX_MTU = 512;

  static const MESSAGE_END = 0;
  static const MESSAGE_BEGIN = 1;

  static const UINT8_SIZE = 256;
}
