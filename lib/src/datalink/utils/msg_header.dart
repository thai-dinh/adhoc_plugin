import 'package:adhoclibrary/src/datalink/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'msg_header.g.dart';


@JsonSerializable()
class Header {
  int _deviceType;
  int _messageType;
  String _label;
  String _name;
  String _address;
  String _mac;
  String _ulid;

  Header({
    @required int messageType, @required String label, @required String name,
    String address = '', String mac = '', String ulid = '', int deviceType
  }) {
    this._messageType = messageType;
    this._label = Utils.checkString(label);
    this._name = Utils.checkString(name);
    this._address = Utils.checkString(address);
    this._mac = Utils.checkString(mac);
    this._ulid = Utils.checkString(ulid);
    this._deviceType = deviceType;
  }

  factory Header.fromJson(Map<String, dynamic> json) => _$HeaderFromJson(json);

  set messageType(int messageType) => this._messageType = messageType;

  int get deviceType => _deviceType;

  int get messageType => _messageType;

  String get label => _label;

  String get name => _name;

  String get address => _address;

  String get mac => _mac;

  String get ulid => _ulid;

  Map<String, dynamic> toJson() => _$HeaderToJson(this);

  @override
  String toString() {
    return 'Header{' +
              'messageType=' + _messageType.toString() +
              ', label=' + _label +
              ', name=' + _name +
              ', address=' + _address +
              ', mac=' + mac +
              ', ulid=' + _ulid +
              ', deviceType=' + _deviceType.toString() + 
            '}';
  }
}
