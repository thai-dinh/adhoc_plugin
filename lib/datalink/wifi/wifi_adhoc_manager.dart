import 'package:AdHocLibrary/datalink/utils/utils.dart';
import 'package:flutter/services.dart';

class WifiAdHocManager {
  static const channel = const MethodChannel('ad.hoc.library.dev/wifi');

  String _adapterName;

  WifiAdHocManager();

  String get adapterName => _adapterName;

  void enable() => Utils.invokeMethod(channel, 'enable');

  void disable() => Utils.invokeMethod(channel, 'disable');
}