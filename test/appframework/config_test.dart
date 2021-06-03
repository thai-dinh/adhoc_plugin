import 'package:adhoc_plugin/src/appframework/config/config.dart';
import 'package:adhoc_plugin/src/appframework/exceptions/bad_server_port.dart';
import 'package:flutter_test/flutter_test.dart';


void main() {
  group('Config tests', () {
    late Config config;

    setUp(() {
      config = Config();
    });

    test('BadServerPortException test', () {
      expect(
        () => config.serverPort = -1,
        throwsA(isInstanceOf<BadServerPortException>())
      );

      expect(
        () => config.serverPort = 999999,
        throwsA(isInstanceOf<BadServerPortException>())
      );
    });

    test('label test', () {
      expect(config.label != '', true);
    });
  });
}
