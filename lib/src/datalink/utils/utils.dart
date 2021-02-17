const DISCOVERY_TIME = 10000;

String checkString(String string) => string == null ? '' : string;

void log(final String tag, final String message) {
  print(tag + ': ' + message);
}
