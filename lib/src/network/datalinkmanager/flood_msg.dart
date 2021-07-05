import 'dart:collection';

import 'package:adhoc_plugin/src/datalink/service/adhoc_device.dart';
import 'package:json_annotation/json_annotation.dart';

part 'flood_msg.g.dart';

/// Class representing a message exchanged if the connection flooding is enabled.
/// It encapsulates information about remote nodes' neighbors.
@JsonSerializable()
class FloodMsg {
  @_HashSetConverter()
  HashSet<AdHocDevice> devices;
  String id;

  /// Creates a [FloodMsg] object.
  ///
  /// The object is given an unique identifier [id] and a set of [AdHocDevice]
  /// representing the neighbors.
  FloodMsg(this.id, this.devices);

  /// Creates a [FloodMsg] object from a JSON representation.
  ///
  /// Factory constructor that creates a [FloodMsg] based on the information given
  /// by [json].
  factory FloodMsg.fromJson(Map<String, dynamic> json) =>
      _$FloodMsgFromJson(json);

/*-------------------------------Public methods-------------------------------*/

  /// Returns the JSON representation as a [Map] of this [FloodMsg] instance.
  Map<String, dynamic> toJson() => _$FloodMsgToJson(this);
}

class _HashSetConverter
    implements JsonConverter<HashSet<AdHocDevice>, Map<String, dynamic>> {
  const _HashSetConverter();

  @override
  HashSet<AdHocDevice> fromJson(Map<String, dynamic> json) {
    var devices = List<AdHocDevice>.empty(growable: true);
    var list = (json['devices'] as List<dynamic>).cast<Map<String, dynamic>>();

    for (var device in list) {
      devices.add(AdHocDevice.fromJson(device));
    }

    return HashSet.from(devices);
  }

  @override
  Map<String, dynamic> toJson(HashSet<AdHocDevice> devices) {
    var map = <String, dynamic>{};

    map['devices'] = List.empty(growable: true)..addAll(devices);

    return map;
  }
}
