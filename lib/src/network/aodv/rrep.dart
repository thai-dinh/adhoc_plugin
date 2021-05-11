import 'package:adhoc_plugin/src/network/aodv/aodv_message.dart';
import 'package:json_annotation/json_annotation.dart';

part 'rrep.g.dart';


@JsonSerializable()
class RREP extends AodvMessage {
  int? _hopCount;
  int? _sequenceNum;
  int? _lifetime;
  String? _destAddress;
  String? _originAddress;

  RREP({
    int? type = 0, int? hopCount = 0, String? destAddress = '',
    int? sequenceNum = 0, String? originAddress = '', int? lifetime = 0
  }) :super(type) {
    this._hopCount = hopCount;
    this._destAddress = destAddress;
    this._sequenceNum = sequenceNum;
    this._originAddress = originAddress;
    this._lifetime = lifetime;
  }

  factory RREP.fromJson(Map<String, dynamic> json) => _$RREPFromJson(json);

/*------------------------------Getters & Setters-----------------------------*/

  int? get hopCount => _hopCount;

  int? get sequenceNum => _sequenceNum;

  int? get lifetime => _lifetime;

  String? get destAddress => _destAddress;

  String? get originAddress => _originAddress;

  int incrementHopCount() {
    _hopCount = _hopCount! + 1;
    return _hopCount!;
  }

  Map<String, dynamic> toJson() => _$RREPToJson(this);

/*------------------------------Override methods------------------------------*/

  @override
  String toString() {
      return 'RREP{' +
                'type=$type' +
                ', hopCount=$_hopCount' +
                ', destAddress=$_destAddress' +
                ', destSeqNum=$_sequenceNum' +
                ', originAddress=$_originAddress' +
                ', lifetime=$_lifetime' +
              '}';
  }
}
