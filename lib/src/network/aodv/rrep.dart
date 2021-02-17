import 'package:adhoclibrary/src/network/aodv/aodv_message.dart';
import 'package:json_annotation/json_annotation.dart';

part 'rrep.g.dart';


@JsonSerializable()
class RREP extends AodvMessage {
  int _hopCount;
  int _sequenceNum;
  int _lifetime;
  String _destIpAddress;
  String _originIpAddress;

  RREP({
    int type = 0, int hopCount = 0, String destIpAddress = '',
    int sequenceNum = 0, String originIpAddress = '', int lifetime = 0
  }) :super(type) {
    this._hopCount = hopCount;
    this._destIpAddress = destIpAddress;
    this._sequenceNum = sequenceNum;
    this._originIpAddress = originIpAddress;
    this._lifetime = lifetime;
  }

  factory RREP.fromJson(Map<String, dynamic> json) => _$RREPFromJson(json);

/*------------------------------Getters & Setters-----------------------------*/

  int get hopCount => _hopCount;

  int get sequenceNum => _sequenceNum;

  int get lifetime => _lifetime;

  String get destIpAddress => _destIpAddress;

  String get originIpAddress => _originIpAddress;

  int incrementHopCount() => ++this._hopCount;

  Map<String, dynamic> toJson() => _$RREPToJson(this);

/*------------------------------Override methods------------------------------*/

  @override
  String toString() {
      return 'RREP{' +
              'type=' + type.toString() +
              ', hopCount=' + _hopCount.toString() +
              ', destIpAddress=' + _destIpAddress +
              ', destSeqNum=' + _sequenceNum.toString() +
              ', originIpAddress=' + _originIpAddress +
              ', lifetime=' + _lifetime.toString() +
              '}';
  }
}
