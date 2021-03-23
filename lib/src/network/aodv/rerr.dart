import 'package:adhoc_plugin/src/network/aodv/aodv_message.dart';
import 'package:json_annotation/json_annotation.dart';

part 'rerr.g.dart';


@JsonSerializable()
class RERR extends AodvMessage {
  String _unreachableDestAddress;
  int _unreachableDestSeqNum;

  RERR({
    int type, String unreachableDestAddress = '', 
    int unreachableDestSeqNum = 0
  }) : super(type) {
    this._unreachableDestAddress = unreachableDestAddress;
    this._unreachableDestSeqNum = unreachableDestSeqNum;
  }

  factory RERR.fromJson(Map<String, dynamic> json) => _$RERRFromJson(json);

/*------------------------------Getters & Setters-----------------------------*/

  String get unreachableDestAddress => _unreachableDestAddress;

  int get unreachableDestSeqNum => _unreachableDestSeqNum;

/*-------------------------------Public methods-------------------------------*/

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

