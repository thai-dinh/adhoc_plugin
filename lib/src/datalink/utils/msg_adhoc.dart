import 'package:adhoc_plugin/src/datalink/utils/msg_header.dart';
import 'package:json_annotation/json_annotation.dart';

part 'msg_adhoc.g.dart';


/// Class defining the structure of messages exchanged by applications 
/// using the plugin.
@JsonSerializable(explicitToJson: true)
class MessageAdHoc {
  late Header header;
  Object? pdu;

  /// Creates a [MessageAdHoc] object.
  /// 
  /// The [header] represents the header information of a message.
  /// 
  /// The [pdu] is a generic object, which represents the PDU (Data) of a 
  /// message.
  MessageAdHoc(this.header, this.pdu);

  /// Creates a [MessageAdHoc] object from a map representation.
  /// 
  /// Factory constructor that creates a [MessageAdHoc] based on the 
  /// information given by [map].
  factory MessageAdHoc.fromMap(Map map) {
    return MessageAdHoc(map['header'] as Header, map['pdu']);
  }

  /// Creates a [MessageAdHoc] object from a JSON representation.
  /// 
  /// Factory constructor that creates a [MessageAdHoc] based on the 
  /// information given by [json].
  factory MessageAdHoc.fromJson(Map<String, dynamic> json) => _$MessageAdHocFromJson(json);

/*-------------------------------Public methods-------------------------------*/

  /// Returns the JSON representation as a [Map] of this [MessageAdHoc] instance.
  Map<String, dynamic> toJson() => _$MessageAdHocToJson(this);

/*------------------------------Override methods------------------------------*/

  @override
  String toString() {
    return 'MessageAdHoc{' + 
              'header=${header.toString()}' +
              ', pdu=${pdu.toString()}' + 
            '}';
  }
}
