import 'package:adhoc_plugin/src/datalink/utils/msg_header.dart';
import 'package:json_annotation/json_annotation.dart';

part 'msg_adhoc.g.dart';


@JsonSerializable(explicitToJson: true)
class MessageAdHoc {
  Header? _header;
  Object? _pdu;

  /// Constructor
  MessageAdHoc([this._header, this._pdu]);

  factory MessageAdHoc.fromMap(Map map) {
    return MessageAdHoc(map['header'], map['pdu']);
  }

  factory MessageAdHoc.fromJson(Map<String, dynamic> json) 
    => _$MessageAdHocFromJson(json);

/*------------------------------Getters & Setters-----------------------------*/

  set header(Header? header) => this._header = header;

  set pdu(Object? pdu) => this._pdu = pdu;

  /// The header object representing the information of the message.
  Header? get header => _header;

  /// Generic object representing the PDU of the message.
  Object? get pdu => _pdu;

/*-------------------------------Public methods-------------------------------*/

  Map<String, dynamic> toJson() => _$MessageAdHocToJson(this);

/*------------------------------Override methods------------------------------*/

  @override
  String toString() {
    return 'MessageAdHoc{' + 
              'header=${_header.toString()}' +
              ', pdu=${_pdu.toString()}' + 
            '}';
  }
}
