import 'package:adhoc_plugin/src/datalink/utils/identifier.dart';
import 'package:adhoc_plugin/src/datalink/utils/utils.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'msg_header.g.dart';


@JsonSerializable()
class Header {
  int _deviceType;
  int _messageType;
  String _label;
  String _name;
  String _address;
  Identifier _mac;

  Header({
    @required int messageType, String label, String name, String address = '', 
    Identifier mac, int deviceType
  }) {
    this._messageType = messageType;
    this._label = checkString(label);
    this._name = checkString(name);
    this._address = checkString(address);
    this._mac = mac;
    this._deviceType = deviceType;
  }

  factory Header.fromJson(Map<String, dynamic> json) => _$HeaderFromJson(json);

/*------------------------------Getters & Setters-----------------------------*/

  set messageType(int messageType) => this._messageType = messageType;

  int get deviceType => _deviceType;

  int get messageType => _messageType;

  String get label => _label;

  String get name => _name;

  String get address => _address;

  Identifier get mac => _mac;

/*-------------------------------Public methods-------------------------------*/

  Map<String, dynamic> toJson() => _$HeaderToJson(this);

/*------------------------------Override methods------------------------------*/

  @override
  String toString() {
    return 'Header{' +
              'messageType=${_messageType.toString()}' +
              ', label=$_label' +
              ', name=$_name' +
              ', address=$_address' +
              ', mac=$_mac' +
              ', deviceType=${_deviceType.toString()}' + 
            '}';
  }
}
