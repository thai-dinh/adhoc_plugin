import 'dart:convert';

import 'package:adhoc_plugin/src/datalink/utils/msg_adhoc.dart';


/// Checks whether the given [string] is null.
/// 
/// Returns '' if it is null, otherwise the given string.
String checkString(String? string) => string == null ? '' : string;


/// Displays the [message] with the [tag] in the log console.
void log(final String tag, final String message) => print(tag + ': ' + message);


/// Splits a string message intro smaller ones.
/// 
/// Returns a list of [MessageAdHoc] containing in [strMessages].
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
