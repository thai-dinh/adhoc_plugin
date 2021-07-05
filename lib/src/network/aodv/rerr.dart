import 'package:adhoc_plugin/src/network/aodv/aodv_message.dart';
import 'package:json_annotation/json_annotation.dart';

part 'rerr.g.dart';

/// Class representing the RERR message for the AODV protocol.
@JsonSerializable()
class RERR extends AodvMessage {
  late String _unreachableDstAddr;
  late int _unreachableDstSeqNum;

  /// Creates a [RERR] object.
  ///
  /// The type of message is specified by [type], the unreachable destination
  /// address is given by [unreachableDstAddr], and its sequence number by
  /// [unreachableDstSeqNum].
  RERR(int type, String unreachableDstAddr, int unreachableDstSeqNum)
      : super(type) {
    _unreachableDstAddr = unreachableDstAddr;
    _unreachableDstSeqNum = unreachableDstSeqNum;
  }

  /// Creates a [RERR] object from a JSON representation.
  ///
  /// Factory constructor that creates a [RERR] based on the information given
  /// by [json].
  factory RERR.fromJson(Map<String, dynamic> json) => _$RERRFromJson(json);

/*------------------------------Getters & Setters-----------------------------*/

  /// Returns the unreachable destination address.
  String get unreachableDstAddr => _unreachableDstAddr;

  /// Returns the unreachable sequence number.
  int get unreachableDstSeqNum => _unreachableDstSeqNum;

/*-------------------------------Public methods-------------------------------*/

  /// Returns the JSON representation as a [Map] of this [RERR] instance.
  Map<String, dynamic> toJson() => _$RERRToJson(this);

/*------------------------------Override methods------------------------------*/

  @override
  String toString() {
    return 'RERR{' +
        'type=$type' +
        ', unreachableDstAddr=$_unreachableDstAddr' +
        ', unreachableDstSeqNum=$_unreachableDstSeqNum' +
        '}';
  }
}
