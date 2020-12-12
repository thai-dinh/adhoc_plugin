import 'package:adhoclibrary/src/datalink/message/msg_header.dart';

class MessageAdHoc {
  Header _header;
  Object _pdu;

  MessageAdHoc([this._header, this._pdu]);

  factory MessageAdHoc.fromMap(Map map) {
    return MessageAdHoc(map['header'], map['pdu']);
  }

  set header(Header header) => this._header = header;

  set pdu(Object pdu) => this._pdu = pdu;

  Header get header => _header;

  Object get pdu => _pdu;

  String toJson() {
    return '{' +
              '"_header" : ' + _header.toJson() +
              '"_pdu" : "$_pdu"' +
            '}';
  }

  @override
  String toString() {
    return 'MessageAdHoc{' + 
              'header=' + _header.toString() +
              ', pdu=' + _pdu.toString() + 
            '}';
  }
}
