import 'package:AdHocLibrary/datalink/utils/utils.dart';
import 'package:flutter/services.dart';

class WifiAdHocManager {
  static const channel = const MethodChannel('ad.hoc.library.dev/wifi');

  String _adapterName;

  WifiAdHocManager();

  String get adapterName => _adapterName;

  void enable() => invokeMethod(channel, 'enable');

  void disable() => invokeMethod(channel, 'disable');
}