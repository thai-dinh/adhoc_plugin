import 'aodv_message.dart';

import 'package:json_annotation/json_annotation.dart';

part 'rerr.g.dart';


/// Class representing the RERR message for the AODV protocol.
@JsonSerializable()
class RERR extends AodvMessage {
  late String _unreachableDestAddress;
  late int _unreachableDestSeqNum;

  /// Creates a [RERR] object.
  /// 
  /// The type of message is specified by [type], the unreachable destination 
  /// address is given by [unreachableDestAddress], and its sequence number by
  /// [unreachableDestSeqNum].
  RERR(
    int type, String unreachableDestAddress, int unreachableDestSeqNum
  ) : super(type) {
    this._unreachableDestAddress = unreachableDestAddress;
    this._unreachableDestSeqNum = unreachableDestSeqNum;
  }

  /// Creates a [RERR] object from a JSON representation.
  /// 
  /// Factory constructor that creates a [RERR] based on the information given 
  /// by [json].
  factory RERR.fromJson(Map<String, dynamic> json) => _$RERRFromJson(json);

/*------------------------------Getters & Setters-----------------------------*/

  /// Returns the unreachable destination address.
  String get unreachableDestAddress => _unreachableDestAddress;

  /// Returns the unreachable sequence number.
  int get unreachableDestSeqNum => _unreachableDestSeqNum;

/*-------------------------------Public methods-------------------------------*/

  /// Returns the JSON representation as a [Map] of this [RERR] instance.
  Map<String, dynamic> toJson() => _$RERRToJson(this);

/*------------------------------Override methods------------------------------*/

  @override
  String toString() {
    return 'RERR{' +
              'type=$type' +
              ', unreachableDestAddress=$_unreachableDestAddress' +
              ', unreachableDestSeqNum=$_unreachableDestSeqNum'  +
            '}';
  }
}

