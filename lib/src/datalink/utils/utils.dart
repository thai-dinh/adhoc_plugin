import 'dart:convert';
import 'dart:typed_data';

import 'package:adhoclibrary/src/datalink/utils/msg_adhoc.dart';


const DISCOVERY_TIME = 10000;

String checkString(String string) => string == null ? '' : string;

void log(final String tag, final String message) {
  print(tag + ': ' + message);
}

MessageAdHoc processMessage(List<Uint8List> data) {
  Uint8List messageAsListByte = 
    Uint8List.fromList(data.expand((x) => List<int>.from(x)..removeAt(0)).toList());
  String strMessage = Utf8Decoder().convert(messageAsListByte);
  return MessageAdHoc.fromJson(json.decode(strMessage));
}
