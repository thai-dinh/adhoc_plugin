import 'dart:convert';
import 'dart:typed_data';

import 'package:adhoclibrary/src/datalink/utils/msg_adhoc.dart';

/*---------------------------------Constants----------------------------------*/

const DISCOVERY_TIME = 10000;

/*-------------------------------Public methods-------------------------------*/

String checkString(String string) => string == null ? '' : string;

void log(final String tag, final String message) => print(tag + ': ' + message);

MessageAdHoc processMessage(List<Uint8List> data) {
  Uint8List messageAsListByte = 
    Uint8List.fromList(data.expand((x) => List<int>.from(x)..removeAt(0)).toList());
  String strMessage = Utf8Decoder().convert(messageAsListByte);
  return MessageAdHoc.fromJson(json.decode(strMessage));
}

List<MessageAdHoc> splitMessages(String strMessages) {
  List<MessageAdHoc> messages = List.empty(growable: true);
  List<String> _strMessages = strMessages.split('}{');

  for (int i = 0; i < _strMessages.length; i++) {
    if (_strMessages.length == 1) {
      messages.add(MessageAdHoc.fromJson(json.decode(_strMessages[i])));
    } else if (i == 0) {
      messages.add(MessageAdHoc.fromJson(json.decode(_strMessages[i] + '}')));
    } else if (i == _strMessages.length - 1) {
      messages.add(MessageAdHoc.fromJson(json.decode('{' + _strMessages[i])));
    } else {
      messages.add(MessageAdHoc.fromJson(json.decode('{' + _strMessages[i] + '}')));
    }
  }

  return messages;
}
