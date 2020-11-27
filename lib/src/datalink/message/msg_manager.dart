import 'dart:convert';
import 'dart:typed_data';

import 'package:adhoclibrary/src/datalink/message/msg_adhoc.dart';
import 'package:adhoclibrary/src/datalink/service/adhoc_device.dart';

class MessageManager {
  AdHocDevice _device;

  MessageManager(this._device);

  void sendMessage(MessageAdHoc msg) {
    List<Uint8List> data = List.empty(growable: true);
    Utf8Encoder encoder = Utf8Encoder();
  }
}