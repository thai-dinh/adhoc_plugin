import 'package:json_annotation/json_annotation.dart';

part 'group_value.g.dart';

/// Class used for sending group value.
@JsonSerializable()
class GroupValue {
  late final String value;

  /// Creates a [GroupValue] object.
  ///
  /// [value] is a value (BigInt).
  GroupValue(this.value);

  /// Creates a [GroupValue] object from a JSON representation.
  ///
  /// Factory constructor that creates a [GroupValue] based on the information
  /// given by [json].
  factory GroupValue.fromJson(Map<String, dynamic> json) =>
      _$GroupValueFromJson(json);

/*-------------------------------Public methods-------------------------------*/

  /// Returns the JSON representation as a [Map] of this [GroupValue] instance.
  Map<String, dynamic> toJson() => _$GroupValueToJson(this);
}
