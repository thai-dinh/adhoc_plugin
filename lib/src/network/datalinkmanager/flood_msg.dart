import 'dart:collection';

import 'package:adhoclibrary/src/datalink/service/adhoc_device.dart';
import 'package:json_annotation/json_annotation.dart';

part 'flood_msg.g.dart';


@JsonSerializable()
class FloodMsg {
  @_HashSetConverter()
  HashSet<AdHocDevice> adHocDevices;
  String id;

  FloodMsg([this.id, this.adHocDevices]);

  factory FloodMsg.fromJson(Map<String, dynamic> json) =>
    _$FloodMsgFromJson(json);

  Map<String, dynamic> toJson() => _$FloodMsgToJson(this);
}

class _HashSetConverter implements JsonConverter<HashSet<AdHocDevice>, Map<String, dynamic>> {
  const _HashSetConverter();

  @override
  HashSet<AdHocDevice> fromJson(Map<String, dynamic> json) {
    List<AdHocDevice> adHocDevices = List.empty(growable: true);
    List<Map<String, dynamic>> list = 
      (json['devices'] as List<dynamic>).cast<Map<String, dynamic>>();

    list.forEach((device) => adHocDevices.add(AdHocDevice.fromJson(device)));

    return HashSet.from(adHocDevices);
  }

  @override
  Map<String, dynamic> toJson(HashSet<AdHocDevice> devices) {
    Map<String, dynamic> map = Map();
    List<Map<String, dynamic>> list = List.empty(growable: true);
    devices.toList().forEach(
      (device) => list.add(device.toJson())
    );

    map['devices'] = list;

    return map;
  }
}
