import 'package:json_annotation/json_annotation.dart';

part 'group_init.g.dart';

@JsonSerializable()
class GroupInit {
  late final String timestamp;
  late final String modulo;
  late final String generator;
  late final String initiator;
  late final bool invitation;

  GroupInit(this.timestamp, this.modulo, this.generator, this.initiator, this.invitation);

  /// Creates a [GroupInit] object from a JSON representation.
  ///
  /// Factory constructor that creates a [GroupInit] based on the information
  /// given by [json].
  factory GroupInit.fromJson(Map<String, dynamic> json) => _$GroupInitFromJson(json);

/*-------------------------------Public methods-------------------------------*/

  /// Returns the JSON representation as a [Map] of this [GroupInit] instance.
  Map<String, dynamic> toJson() => _$GroupInitToJson(this);
}