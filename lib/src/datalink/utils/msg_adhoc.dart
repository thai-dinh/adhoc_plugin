import 'package:json_annotation/json_annotation.dart';

import 'msg_header.dart';

part 'msg_adhoc.g.dart';


/// Class defining the structure of messages exchanged by applications 
/// using the plugin.
@JsonSerializable(explicitToJson: true)
class MessageAdHoc {
  Object? _pdu;

  late Header _header;

  /// Creates a [MessageAdHoc] object.
  /// 
  /// The [header] represents the header information of a message.
  /// 
  /// The [pdu] is a generic object, which represents the PDU (Data) of a 
  /// message.
  MessageAdHoc(Header header, Object? pdu) {
    this._header = header;
    this._pdu = pdu;
  }

  /// Creates a [MessageAdHoc] object from a map representation.
  /// 
  /// Factory constructor that creates a [MessageAdHoc] based on the 
  /// information given by [map].
  factory MessageAdHoc.fromMap(Map map) {
    return MessageAdHoc(map['header'], map['pdu']);
  }

  /// Creates a [MessageAdHoc] object from a JSON representation.
  /// 
  /// Factory constructor that creates a [MessageAdHoc] based on the 
  /// information given by [json].
  factory MessageAdHoc.fromJson(Map<String, dynamic> json) => _$MessageAdHocFromJson(json);

/*------------------------------Getters & Setters-----------------------------*/

  /// Sets the new [header] of this [MessageAdHoc] instance.
  set header(Header header) => this._header = header;

  /// Sets the new [pdu] of this [MessageAdHoc] instance.
  set pdu(Object? pdu) => this._pdu = pdu;

  /// Return the header of this [MessageAdHoc] instance.
  Header get header => _header;

  /// Return the PDU (data) of this [MessageAdHoc] instance.
  Object? get pdu => _pdu;

/*-------------------------------Public methods-------------------------------*/

  /// Returns the JSON representation as a [Map] of this [MessageAdHoc] instance.
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
