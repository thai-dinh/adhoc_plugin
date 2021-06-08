import 'package:json_annotation/json_annotation.dart';

part 'group_join.g.dart';

/// Class used for join group request.
@JsonSerializable()
class GroupJoin {
  String? hash;
  List<String>? labels;
  List<String>? values;

  String? share;
  String? solution;

  /// Creates a [GroupJoin] object.
  /// 
  /// [hash] represents the hash of the group key.
  /// 
  /// [labels] is the list of members' labels.
  /// 
  /// [values] is the members' public shares.
  /// 
  /// [solution] is the CRT solution value.
  GroupJoin({this.hash, this.labels, this.values, this.share, this.solution});

  /// Creates a [GroupJoin] object from a JSON representation.
  ///
  /// Factory constructor that creates a [GroupJoin] based on the information
  /// given by [json].
  factory GroupJoin.fromJson(Map<String, dynamic> json) => _$GroupJoinFromJson(json);

/*-------------------------------Public methods-------------------------------*/

  /// Returns the JSON representation as a [Map] of this [GroupJoin] instance.
  Map<String, dynamic> toJson() => _$GroupJoinToJson(this);
}