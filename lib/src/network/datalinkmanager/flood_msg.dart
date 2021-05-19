import 'dart:collection';

import 'package:adhoc_plugin/src/datalink/service/adhoc_device.dart';
import 'package:json_annotation/json_annotation.dart';

part 'flood_msg.g.dart';


@JsonSerializable()
class FloodMsg {
  @_HashSetConverter()
  HashSet<AdHocDevice?> devices;
  String? id;

  FloodMsg(this.id, this.devices);

  factory FloodMsg.fromJson(Map<String, dynamic> json) => _$FloodMsgFromJson(json);

/*-------------------------------Public methods-------------------------------*/

  Map<String, dynamic> toJson() => _$FloodMsgToJson(this);
}

class _HashSetConverter implements JsonConverter<HashSet<AdHocDevice?>, Map<String, dynamic>> {
  const _HashSetConverter();

  @override
  HashSet<AdHocDevice?> fromJson(Map<String, dynamic> json) {
    List<AdHocDevice> devices = List.empty(growable: true);
    List<Map<String, dynamic>> list = 
      (json['devices'] as List<dynamic>).cast<Map<String, dynamic>>();

    list.forEach((device) => devices.add(AdHocDevice.fromJson(device)));

    return HashSet.from(devices);
  }

  @override
  Map<String, dynamic> toJson(HashSet<AdHocDevice?> devices) {
    Map<String, dynamic> map = Map();

    map['devices'] = List.empty(growable: true)..addAll(devices);

    return map;
  }
}
