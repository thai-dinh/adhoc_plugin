import 'package:json_annotation/json_annotation.dart';

part 'group_leave.g.dart';

@JsonSerializable()
class GroupLeave {
  late final String leavingLabel;
  String? newSolution;

  GroupLeave(this.leavingLabel, {this.newSolution});

  /// Creates a [GroupLeave] object from a JSON representation.
  ///
  /// Factory constructor that creates a [GroupLeave] based on the information
  /// given by [json].
  factory GroupLeave.fromJson(Map<String, dynamic> json) => _$GroupLeaveFromJson(json);

/*-------------------------------Public methods-------------------------------*/

  /// Returns the JSON representation as a [Map] of this [GroupLeave] instance.
  Map<String, dynamic> toJson() => _$GroupLeaveToJson(this);
}