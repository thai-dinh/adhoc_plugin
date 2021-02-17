import 'package:adhoclibrary/src/network/aodv/aodv_message.dart';
import 'package:json_annotation/json_annotation.dart';

part 'rerr.g.dart';


@JsonSerializable()
class RERR extends AodvMessage {
  String _unreachableDestIpAddress;
  int _unreachableDestSeqNum;

  RERR({
    int type, String unreachableDestIpAddress = '', 
    int unreachableDestSeqNum = 0
  }) : super(type) {
    this._unreachableDestIpAddress = unreachableDestIpAddress;
    this._unreachableDestSeqNum = unreachableDestSeqNum;
  }

/*------------------------------Getters & Setters-----------------------------*/

  String get unreachableDestIpAddress => _unreachableDestIpAddress;

  int get unreachableDestSeqNum => _unreachableDestSeqNum;

/*------------------------------Override methods------------------------------*/

  @override
  String toString() {
    return 'RERR{' +
            'type=' + type.toString() +
            ', unreachableDestIpAddress=' + _unreachableDestIpAddress +
            ', unreachableDestSeqNum=' + _unreachableDestSeqNum.toString()  +
          '}';
  }
}

