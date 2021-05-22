import 'dart:convert';

import 'package:adhoc_plugin/src/datalink/utils/msg_adhoc.dart';


String checkString(String? string) => string == null ? '' : string;

void log(final String tag, final String message) => print(tag + ': ' + message);

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
