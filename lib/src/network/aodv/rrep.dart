import 'package:adhoc_plugin/src/network/aodv/aodv_message.dart';
import 'package:adhoc_plugin/src/secure_data/certificate.dart';
import 'package:json_annotation/json_annotation.dart';

part 'rrep.g.dart';


@JsonSerializable()
class RREP extends AodvMessage {
  late int _sequenceNum;
  late int _hopCount;
  late int _lifetime;
  late String _destAddress;
  late String _originAddress;

  late List<Certificate> certChain;

  RREP(
    int type, int hopCount, String destAddress, int sequenceNum, 
    String originAddress, int lifetime, List<Certificate> certChain
  ) : super(type) {
    this._sequenceNum = sequenceNum;
    this._hopCount = hopCount;
    this._lifetime = lifetime;
    this._destAddress = destAddress;
    this._originAddress = originAddress;
    this.certChain = certChain;
  }

  factory RREP.fromJson(Map<String, dynamic> json) => _$RREPFromJson(json);

/*------------------------------Getters & Setters-----------------------------*/

  int get hopCount => _hopCount;

  int get sequenceNum => _sequenceNum;

  int get lifetime => _lifetime;

  String get destAddress => _destAddress;

  String get originAddress => _originAddress;

  int incrementHopCount() => _hopCount = _hopCount + 1;

/*-------------------------------Public methods-------------------------------*/

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
