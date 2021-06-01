import 'package:json_annotation/json_annotation.dart';

import 'aodv_message.dart';
import '../../presentation/certificate.dart';

part 'rreq.g.dart';


/// Class representing the RREQ message for the AODV protocol.
@JsonSerializable()
class RREQ extends AodvMessage {
  late int _hopCount;
  late int _rreqId;
  late int dstSeqNum;
  late String _dstAddr;
  late int _srcSeqNum;
  late String _srcAddr;

  late int ttl;
  late List<Certificate> chain;

  /// Creates a [RREQ] object.
  /// 
  /// The type of message is specified by [type], the hops number of the RREQ 
  /// message is given by [hopCount], the broadcast ID [rreqId] of the RREQ 
  /// message, the destination address is set to [dstAddr], the destination 
  /// sequence number is set to [dstSeqNum], the source address is given by 
  /// [srcAddr], and its source sequence number by [srcSeqNum].
  /// 
  /// The list of certificate chain [chain] is used for the certificate 
  /// chain discovery process.
  RREQ(
    int type, int hopCount, int rreqId, this.dstSeqNum, String dstAddr, 
    int srcSeqNum, String srcAddr, int ttl, List<Certificate> chain
  ) : super(type) {
    this._hopCount = hopCount;
    this._rreqId = rreqId;
    this._dstAddr = dstAddr;
    this._srcSeqNum = srcSeqNum;
    this._srcAddr = srcAddr;
    this.ttl = ttl;
    this.chain = chain;
  }

  /// Creates a [RREQ] object from a JSON representation.
  /// 
  /// Factory constructor that creates a [RREQ] based on the information given 
  /// by [json].
  factory RREQ.fromJson(Map<String, dynamic> json) => _$RREQFromJson(json);

/*------------------------------Getters & Setters-----------------------------*/

  /// Hop count of the RREQ message.
  int get hopCount => _hopCount = _hopCount + 1;

  /// Broadcast ID of the RREQ message.
  int get rreqId => _rreqId;

  /// Destination address of the RREQ message.
  String get dstAddr => _dstAddr;

  /// Source hop count of the RREQ message.
  int get srcSeqNum => _srcSeqNum;

  /// Source address of the RREQ message.
  String get srcAddr => _srcAddr;

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
            ', dstSeqNum=$dstSeqNum' +
            ', dstAddr=$_dstAddr' +
            ', srcSeqNum=$_srcSeqNum' +
            ', srcAddr=$_srcAddr' +
          '}';
  }
}