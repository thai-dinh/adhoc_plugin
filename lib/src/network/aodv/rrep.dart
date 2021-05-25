import 'aodv_message.dart';
import '../../presentation/certificate.dart';

import 'package:json_annotation/json_annotation.dart';

part 'rrep.g.dart';


/// Class representing the RREP message for the AODV protocol.
@JsonSerializable()
class RREP extends AodvMessage {
  late int _seqNum;
  late int _hopCount;
  late int _lifetime;
  late String _dstAddress;
  late String _srcAddress;

  late List<Certificate> certChain;

  /// Creates a [RREP] object.
  /// 
  /// The type of message is specified by [type], the hops number of the RREP 
  /// message is given by [hopCount], the destination address is set to 
  /// [dstAddress], the sequence number is set to [seqNum], the source address
  /// is given by [srcAddress], and the lifetime of the RREP message is set
  /// to [lifetime].
  /// 
  /// The list of certificate chain [certChain] is used for the certificate 
  /// chain discovery process.
  RREP(
    int type, int hopCount, String dstAddress, int seqNum, 
    String srcAddress, int lifetime, List<Certificate> certChain
  ) : super(type) {
    this._seqNum = seqNum;
    this._hopCount = hopCount;
    this._lifetime = lifetime;
    this._dstAddress = dstAddress;
    this._srcAddress = srcAddress;
    this.certChain = certChain;
  }

  /// Creates a [RREP] object from a JSON representation.
  /// 
  /// Factory constructor that creates a [RREP] based on the information given 
  /// by [json].
  factory RREP.fromJson(Map<String, dynamic> json) => _$RREPFromJson(json);

/*------------------------------Getters & Setters-----------------------------*/

  /// Returns the hop count of the RREP message.
  int get hopCount => _hopCount;

  /// Returns the sequence number of the RREP message.
  int get seqNum => _seqNum;

  /// Returns the lifetime of the RREP message.
  int get lifetime => _lifetime;

  /// Returns the destination addresss of the RREP message.
  String get dstAddress => _dstAddress;

  /// Returns the source address of the RREP message.
  String get srcAddress => _srcAddress;

  /// Returns the hop count incremeted by one of the RREP message.
  int incrementHopCount() => _hopCount = _hopCount + 1;

/*-------------------------------Public methods-------------------------------*/
  
  /// Returns the JSON representation as a [Map] of this [RREP] instance.
  Map<String, dynamic> toJson() => _$RREPToJson(this);

/*------------------------------Override methods------------------------------*/

  @override
  String toString() {
      return 'RREP{' +
                'type=$type' +
                ', hopCount=$_hopCount' +
                ', dstAddress=$_dstAddress' +
                ', destSeqNum=$_seqNum' +
                ', srcAddress=$_srcAddress' +
                ', lifetime=$_lifetime' +
              '}';
  }
}
