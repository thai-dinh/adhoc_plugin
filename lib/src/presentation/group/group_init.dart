import 'package:json_annotation/json_annotation.dart';

part 'group_init.g.dart';

/// Class used for group advertisement.
@JsonSerializable()
class GroupInit {
  late final String timestamp;
  late final String modulo;
  late final String generator;
  late final String initiator;
  late final bool invitation;

  /// Creates a [GroupInit] object.
  ///
  /// [timestamp] allows to control the flood of advertisement.
  ///
  /// [modulo] prime value of the cyclic group, where [generator] is a value of it.
  ///
  /// [initiator] represents the label of the node that initiates a group formation.
  ///
  /// If [invitation] is set to true, then the advertisement is to be sent to a particular peer.
  /// Otherwise, it is broadcasted.
  GroupInit(this.timestamp, this.modulo, this.generator, this.initiator,
      this.invitation);

  /// Creates a [GroupInit] object from a JSON representation.
  ///
  /// Factory constructor that creates a [GroupInit] based on the information
  /// given by [json].
  factory GroupInit.fromJson(Map<String, dynamic> json) =>
      _$GroupInitFromJson(json);

/*-------------------------------Public methods-------------------------------*/

  /// Returns the JSON representation as a [Map] of this [GroupInit] instance.
  Map<String, dynamic> toJson() => _$GroupInitToJson(this);
}
