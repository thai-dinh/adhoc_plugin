import 'package:AdHocLibrary/datalink/utils/header.dart';

import 'package:json_annotation/json_annotation.dart';

part 'message_adhoc.g.dart';

@JsonSerializable()
class MessageAdHoc {
  Header _header;

  MessageAdHoc([this._header]);

  factory MessageAdHoc.fromJson(Map<String, dynamic> json) 
    => _$MessageAdHocFromJson(json);

  Map<String, dynamic> toJson() => _$MessageAdHocToJson(this);

  set header(Header header) => this._header = header;

  Header get header => _header;
}