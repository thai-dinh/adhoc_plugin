import 'package:json_annotation/json_annotation.dart';

part 'msg_header.g.dart';


@JsonSerializable()
class Header {
  int _deviceType;
  int _messageType;
  String _address;
  String _label;
  String _name;

  Header(int messageType, String label, String name, String address) {
    this._messageType = messageType;
    this._label = label;
    this._name = name;
    this._address = address;
  }

  factory Header.fromJson(Map<String, dynamic> json) => _$HeaderFromJson(json);

  set messageType(int messageType) => this._messageType = messageType;

  int get deviceType => _deviceType;

  int get messageType => _messageType;

  String get label => _label;

  String get name => _name;

  String get address => _address;

  Map<String, dynamic> toJson() => _$HeaderToJson(this);

  @override
  String toString() {
    return 'Header{' +
              '_messageType=' + _messageType.toString() +
              ', label=' + _label +
              ', name=' + _name +
              ', address=' + _address +
            '}';
  }
}
