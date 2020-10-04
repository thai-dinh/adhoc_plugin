import 'package:AdHocLibrary/src/datalink/utils/header.dart';

class MessageAdHoc {
  Header _header;

  MessageAdHoc([this._header]);

  void setHeader(Header header) {
    this._header = header;
  }

  Header getHeader() => _header;

  String toString() => "MessageAdHoc{" +
                        "header=" + _header.toString() +
                        // ", pdu=" + pdu +
                        '}';
}