import 'package:adhoc_plugin/src/datalink/utils/utils.dart';
import 'package:json_annotation/json_annotation.dart';

part 'msg_header.g.dart';


@JsonSerializable()
class Header {
  String? _label;
  String? _name;
  String? _mac;
  int? _messageType;

  String? address;
  int? deviceType;

  Header({
    required int? messageType, String? label, String? name, String? address, 
    String? mac, int? deviceType
  }) {
    this._messageType = messageType;
    this._label = checkString(label);
    this._name = checkString(name);
    this._mac = mac;
    this.address = address;
    this.deviceType = deviceType;
  }

  factory Header.fromJson(Map<String, dynamic> json) => _$HeaderFromJson(json);

/*------------------------------Getters & Setters-----------------------------*/

  set messageType(int? messageType) => this._messageType = messageType;

  int? get messageType => _messageType;

  String? get label => _label;

  String? get name => _name;

  String? get mac => _mac;

/*-------------------------------Public methods-------------------------------*/

  Map<String, dynamic> toJson() => _$HeaderToJson(this);

/*------------------------------Override methods------------------------------*/

  @override
  String toString() {
    return 'Header{' +
              'messageType=${_messageType.toString()}' +
              ', label=$_label' +
              ', name=$_name' +
              ', address=$address' +
              ', mac=$_mac' +
              ', deviceType=${deviceType.toString()}' + 
            '}';
  }
}
