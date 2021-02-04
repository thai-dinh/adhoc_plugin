import 'package:adhoclibrary/src/datalink/utils/msg_header.dart';
import 'package:json_annotation/json_annotation.dart';

part 'msg_adhoc.g.dart';


@JsonSerializable(explicitToJson: true)
class MessageAdHoc {
  Header _header;
  Object _pdu;

  /// Constructor
  MessageAdHoc([this._header, this._pdu]);

  factory MessageAdHoc.fromMap(Map map) {
    return MessageAdHoc(map['header'], map['pdu']);
  }

  factory MessageAdHoc.fromJson(Map<String, dynamic> json) 
    => _$MessageAdHocFromJson(json);

  set header(Header header) => this._header = header;

  set pdu(Object pdu) => this._pdu = pdu;

  /// The header object representing the information of the message.
  Header get header => _header;

  /// Generic object representing the PDU of the message.
  Object get pdu => _pdu;

  Map<String, dynamic> toJson() => _$MessageAdHocToJson(this);

  @override
  String toString() {
    return 'MessageAdHoc{' + 
              'header=' + _header.toString() +
              ', pdu=' + _pdu.toString() + 
            '}';
  }
}
