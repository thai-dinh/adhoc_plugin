import 'dart:async';

import 'package:flutter/services.dart';

const String UUID = 'e0917680-d427-11e4-8830-';

Future<dynamic> invokeMethod(MethodChannel channel, String method, 
                             [dynamic arguments]) async
{
  dynamic _value;

  try {
    _value = await channel.invokeMethod(method, arguments);
  } on PlatformException catch (error) {
    print(error.message);
  }

  return _value;
}
