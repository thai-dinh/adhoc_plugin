import 'package:json_annotation/json_annotation.dart';

part 'header.g.dart';

@JsonSerializable()
class Header {
  int _deviceType;
  int _type;
  String _address;
  String _label;
  String _mac;
  String _name;

  Header();

  Header.init(this._type, this._label, this._name, 
             [this._mac, this._address, this._deviceType]);

  factory Header.fromJson(Map<String, dynamic> json) => _$HeaderFromJson(json);

  Map<String, dynamic> toJson() => _$HeaderToJson(this);

  set type(int type) => this._type = type;

  int get deviceType => _deviceType;

  int get type => _type;

  String get address => _address;

  String get label => _label;

  String get mac => _mac;

  String get name => _name;
}