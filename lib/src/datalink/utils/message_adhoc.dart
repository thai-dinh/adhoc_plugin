import 'package:AdHocLibrary/src/datalink/utils/header.dart';

class MessageAdHoc {
  Header _header;

  MessageAdHoc([this._header]);

  set header(Header header) => this._header = header;

  Header get header => _header;

  String toString() => "MessageAdHoc{" +
                        "header=" + _header.toString() +
                        // ", pdu=" + pdu +
                        '}';
}