import 'package:adhoclibrary/src/message/msg_header.dart';

class MessageAdHoc {
  Header _header;
  Object _pdu;

  MessageAdHoc([this._header, this._pdu]);

  set header(Header header) => this._header = header;

  set pdu(Object pdu) => this._pdu = pdu;

  Header get header => _header;

  Object get pdu => _pdu;
}