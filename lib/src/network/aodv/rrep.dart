import 'package:adhoc_plugin/src/network/aodv/aodv_message.dart';
import 'package:adhoc_plugin/src/presentation/key_mgnmt/certificate.dart';
import 'package:json_annotation/json_annotation.dart';

part 'rrep.g.dart';

/// Class representing the RREP message for the AODV protocol.
@JsonSerializable()
class RREP extends AodvMessage {
  late int _seqNum;
  late int _hopCount;
  late int _lifetime;
  late String _dstAddr;
  late String _srcAddr;

  late List<Certificate> chain;

  /// Creates a [RREP] object.
  ///
  /// The type of message is specified by [type], the hops number of the RREP
  /// message is given by [hopCount], the destination address is set to
  /// [dstAddr], the sequence number is set to [seqNum], the source address
  /// is given by [srcAddr], and the lifetime of the RREP message is set
  /// to [lifetime].
  ///
  /// The list of certificate [chain] is used for the certificate
  /// chain discovery process.
  RREP(int type, int hopCount, String dstAddr, int seqNum, String srcAddr,
      int lifetime, List<Certificate> chain)
      : super(type) {
    this.chain = chain;
    _seqNum = seqNum;
    _hopCount = hopCount;
    _lifetime = lifetime;
    _dstAddr = dstAddr;
    _srcAddr = srcAddr;
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
  String get dstAddr => _dstAddr;

  /// Returns the source address of the RREP message.
  String get srcAddr => _srcAddr;

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
        ', dstAddr=$_dstAddr' +
        ', destSeqNum=$_seqNum' +
        ', srcAddr=$_srcAddr' +
        ', lifetime=$_lifetime' +
        '}';
  }
}
