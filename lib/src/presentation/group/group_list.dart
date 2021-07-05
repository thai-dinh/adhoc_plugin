import 'package:json_annotation/json_annotation.dart';

part 'group_list.g.dart';

/// Class used sending the list of group members.
@JsonSerializable()
class GroupList {
  late final List<String> labels;

  /// Creates a [GroupList] object.
  ///
  /// [labels] is a list of members labels.
  GroupList(this.labels);

  /// Creates a [GroupList] object from a JSON representation.
  ///
  /// Factory constructor that creates a [GroupList] based on the information
  /// given by [json].
  factory GroupList.fromJson(Map<String, dynamic> json) =>
      _$GroupListFromJson(json);

/*-------------------------------Public methods-------------------------------*/

  /// Returns the JSON representation as a [Map] of this [GroupList] instance.
  Map<String, dynamic> toJson() => _$GroupListToJson(this);
}
