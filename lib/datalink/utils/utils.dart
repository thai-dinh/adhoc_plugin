import 'dart:async';

import 'package:flutter/services.dart';

class Utils {
  static Future<dynamic> invokeMethod(MethodChannel channel, String method, 
                                     [dynamic arguments]) async {
    dynamic _value;

    try {
      _value = await channel.invokeMethod(method, arguments);
    } on PlatformException catch (error) {
      print(error.message);
    }

    return _value;
  }
}