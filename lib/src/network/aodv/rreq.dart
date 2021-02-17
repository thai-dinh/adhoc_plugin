import 'package:adhoclibrary/src/network/aodv/aodv_message.dart';
import 'package:json_annotation/json_annotation.dart';

part 'rreq.g.dart';


@JsonSerializable()
class RREQ extends AodvMessage {
  int _hopCount;
  int _rreqId;
  int _destSequenceNum;
  String _destIpAddress;
  int _originSequenceNum;
  String _originIpAddress;

  RREQ({
    int type = 0, int hopCount = 0, int rreqId = 0, 
    int destSequenceNum = 0, String destIpAddress = '', 
    int originSequenceNum = 0, String originIpAddress = ''
  }) : super(type) {
    this._hopCount = hopCount;
    this._rreqId = rreqId;
    this._destSequenceNum = destSequenceNum;
    this._destIpAddress = destIpAddress;
    this._originSequenceNum = originSequenceNum;
    this._originIpAddress = originIpAddress;
  }

  factory RREQ.fromJson(Map<String, dynamic> json) => _$RREQFromJson(json);

/*------------------------------Getters & Setters-----------------------------*/

  int get hopCount => _hopCount;

  int get rreqId => _rreqId;

  int get destSequenceNum => _destSequenceNum;

  String get destIpAddress => _destIpAddress;

  int get originSequenceNum => _originSequenceNum;

  String get originIpAddress => _originIpAddress;

  set destSequenceNum(int destSequenceNum) => _destSequenceNum = destSequenceNum;

/*-------------------------------Public methods-------------------------------*/

  void incrementHopCount() => this._hopCount++;

  Map<String, dynamic> toJson() => _$RREQToJson(this);

/*------------------------------Override methods------------------------------*/

  @override
  String toString() {
    return 'RREQ{' +
            'type=' + type.toString() +
            ', hopCount=' + _hopCount.toString() +
            ', rreqId=' + _rreqId.toString() +
            ', destSequenceNum=' + _destSequenceNum.toString() +
            ', destIpAddress=' + _destIpAddress  +
            ', originSequenceNum=' + _originSequenceNum.toString() +
            ', originIpAddress=' + _originIpAddress +
          '}';
  }
}