class Utils {
  static const DISCOVERY_TIME = 10000;

  static const BLE_STATE_CONNECTED = 1;

  static String checkString(String string) => string == null ? '' : string;

  static void log(final String tag, final String message) {
    print(tag + ': ' + message);
  }
}
