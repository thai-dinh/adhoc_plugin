import 'aodv_message.dart';
import '../../presentation/certificate.dart';

import 'package:json_annotation/json_annotation.dart';

part 'rreq.g.dart';


/// Class representing the RREQ message for the AODV protocol.
@JsonSerializable()
class RREQ extends AodvMessage {
  late int _hopCount;
  late int _rreqId;
  late int destSeqNum;
  late String _dstAddress;
  late int _srcSeqNum;
  late String _srcAddress;

  late int ttl;
  late List<Certificate> certChain;

  /// Creates a [RREQ] object.
  /// 
  /// The type of message is specified by [type], the hops number of the RREQ 
  /// message is given by [hopCount], the broadcast ID [rreqId] of the RREQ 
  /// message, the destination address is set to [dstAddress], the destination 
  /// sequence number is set to [destSeqNum], the source address is given by 
  /// [srcAddress], and its source sequence number by [srcSeqNum].
  /// 
  /// The list of certificate chain [certChain] is used for the certificate 
  /// chain discovery process.
  RREQ(
    int type, int hopCount, int rreqId, this.destSeqNum, String dstAddress, 
    int srcSeqNum, String srcAddress, int ttl, List<Certificate> certChain
  ) : super(type) {
    this._hopCount = hopCount;
    this._rreqId = rreqId;
    this._dstAddress = dstAddress;
    this._srcSeqNum = srcSeqNum;
    this._srcAddress = srcAddress;
    this.ttl = ttl;
    this.certChain = certChain;
  }

  /// Creates a [RREQ] object from a JSON representation.
  /// 
  /// Factory constructor that creates a [RREQ] based on the information given 
  /// by [json].
  factory RREQ.fromJson(Map<String, dynamic> json) => _$RREQFromJson(json);

/*------------------------------Getters & Setters-----------------------------*/

  /// Returns the hop count of the RREQ message.
  int get hopCount => _hopCount = _hopCount + 1;

  /// Returns the broadcast ID of the RREQ message.
  int get rreqId => _rreqId;

  /// Returns the destination address of the RREQ message.
  String get dstAddress => _dstAddress;

  /// Returns the source hop count of the RREQ message.
  int get srcSeqNum => _srcSeqNum;

  /// Returns the source address of the RREQ message.
  String get srcAddress => _srcAddress;

/*-------------------------------Public methods-------------------------------*/

  /// Increments the hop count of the RREQ message.
  void incrementHopCount() => this._hopCount = this._hopCount + 1;

  /// Decrements the TTL of the RREQ message.
  void decrementTTL() => this.ttl = this.ttl - 1;

  /// Returns the JSON representation as a [Map] of this [RREQ] instance.
  Map<String, dynamic> toJson() => _$RREQToJson(this);

/*------------------------------Override methods------------------------------*/

  @override
  String toString() {
    return 'RREQ{' +
            'type=$type' +
            ', hopCount=$_hopCount' +
            ', rreqId=$_rreqId' +
            ', destSeqNum=$destSeqNum' +
            ', dstAddress=$_dstAddress' +
            ', srcSeqNum=$_srcSeqNum' +
            ', srcAddress=$_srcAddress' +
          '}';
  }
}