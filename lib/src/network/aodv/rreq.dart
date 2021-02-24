import 'package:adhoclibrary/src/network/aodv/aodv_message.dart';
import 'package:json_annotation/json_annotation.dart';

part 'rreq.g.dart';


@JsonSerializable()
class RREQ extends AodvMessage {
  int _hopCount;
  int _rreqId;
  int destSequenceNum;
  String _destAddress;
  int _originSequenceNum;
  String _originAddress;

  RREQ({
    int type = 0, int hopCount = 0, int rreqId = 0, 
    this.destSequenceNum = 0, String destAddress = '', 
    int originSequenceNum = 0, String originAddress = ''
  }) : super(type) {
    this._hopCount = hopCount;
    this._rreqId = rreqId;
    this._destAddress = destAddress;
    this._originSequenceNum = originSequenceNum;
    this._originAddress = originAddress;
  }

  factory RREQ.fromJson(Map<String, dynamic> json) => _$RREQFromJson(json);

/*------------------------------Getters & Setters-----------------------------*/

  int get hopCount => _hopCount;

  int get rreqId => _rreqId;

  String get destAddress => _destAddress;

  int get originSequenceNum => _originSequenceNum;

  String get originAddress => _originAddress;

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
            ', destSequenceNum=' + destSequenceNum.toString() +
            ', destAddress=' + _destAddress  +
            ', originSequenceNum=' + _originSequenceNum.toString() +
            ', originAddress=' + _originAddress +
          '}';
  }
}