import 'package:adhoc_plugin/src/network/aodv/aodv_message.dart';
import 'package:adhoc_plugin/src/secure_data/certificate.dart';
import 'package:json_annotation/json_annotation.dart';

part 'rreq.g.dart';


@JsonSerializable()
class RREQ extends AodvMessage {
  late int _hopCount;
  late int _rreqId;
  late int destSequenceNum;
  late String _destAddress;
  late int _originSequenceNum;
  late String _originAddress;

  late List<Certificate> certChain;

  RREQ(
    int type, int hopCount, int rreqId, this.destSequenceNum, 
    String destAddress, int originSequenceNum, String originAddress,
    List<Certificate> certChain
  ) : super(type) {
    this._hopCount = hopCount;
    this._rreqId = rreqId;
    this._destAddress = destAddress;
    this._originSequenceNum = originSequenceNum;
    this._originAddress = originAddress;
    this.certChain = certChain;
  }

  factory RREQ.fromJson(Map<String, dynamic> json) => _$RREQFromJson(json);

/*------------------------------Getters & Setters-----------------------------*/

  int get hopCount => _hopCount = _hopCount + 1;

  int get rreqId => _rreqId;

  String get destAddress => _destAddress;

  int get originSequenceNum => _originSequenceNum;

  String get originAddress => _originAddress;

/*-------------------------------Public methods-------------------------------*/

  void incrementHopCount() => this._hopCount;

  Map<String, dynamic> toJson() => _$RREQToJson(this);

/*------------------------------Override methods------------------------------*/

  @override
  String toString() {
    return 'RREQ{' +
            'type=$type' +
            ', hopCount=$_hopCount' +
            ', rreqId=$_rreqId' +
            ', destSequenceNum=$destSequenceNum' +
            ', destAddress=$_destAddress' +
            ', originSequenceNum=$_originSequenceNum' +
            ', originAddress=$_originAddress' +
          '}';
  }
}