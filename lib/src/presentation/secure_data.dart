import 'package:json_annotation/json_annotation.dart';

part 'secure_data.g.dart';


/// Class encapsulating the presentation data.
@JsonSerializable()
class SecureData {
  Object? payload;

  late int type;

  /// Creates an [SecureData] object.
  /// 
  /// The type of message is specified by [type], which determines the 
  /// structure of [payload].
  SecureData(this.type, this.payload);

  /// Creates a [SecureData] object from a JSON representation.
  /// 
  /// Factory constructor that creates a [SecureData] based on the information
  /// given by [json].
  factory SecureData.fromJson(Map<String, dynamic> json) 
    => _$SecureDataFromJson(json);

/*-------------------------------Public methods-------------------------------*/

  /// Returns the JSON representation as a [Map] of this [SecureData] instance.
  Map<String, dynamic> toJson() => _$SecureDataToJson(this);
}
