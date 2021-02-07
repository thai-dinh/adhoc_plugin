class Utils {
  static const DISCOVERY_TIME = 10000;

  static String checkString(String string) => string == null ? '' : string;

  static void log(final String tag, final String message) {
    print(tag + ': ' + message);
  }
}
