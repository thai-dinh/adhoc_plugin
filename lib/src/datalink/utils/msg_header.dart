import '../utils/utils.dart';

import 'package:json_annotation/json_annotation.dart';

part 'msg_header.g.dart';


/// Class representing the header structure of messages exchanged by 
/// applications using the plugin.
@JsonSerializable()
class Header {
  String? _name;
  String? _mac;

  late String _label;
  late int _messageType;

  String? address;
  int? deviceType;

  /// Creates a [Header] object.
  /// 
  /// The [messageType] indicates the type of message exchanged. The [label]
  /// uniquely identifies the device along with its [name] and MAC address [mac]. 
  /// 
  /// The [address] represents the device logical address (UUID for Bluetooth LE 
  /// and IP for Wi-Fi).
  /// 
  /// The type of technology used by the device is determined by [deviceType].
  /// It can be either Bluetooth Low Energy or Wi-Fi Direct.
  Header({
    required int messageType, required String label, String? name, 
    String? address, String? mac, int? deviceType
  }) {
    this._messageType = messageType;
    this._label = checkString(label);
    this._name = checkString(name);
    this._mac = mac;
    this.address = address;
    this.deviceType = deviceType;
  }

  /// Creates a [Header] object from a JSON representation.
  /// 
  /// Factory constructor that constructs a [Header] based on the information
  /// given by [json].
  factory Header.fromJson(Map<String, dynamic> json) => _$HeaderFromJson(json);

/*------------------------------Getters & Setters-----------------------------*/

  /// Sets the message type to [messageType].
  set messageType(int messageType) => this._messageType = messageType;

  /// Returns the type of the message.
  int get messageType => _messageType;

  /// Returns the sender label.
  String get label => _label;

  /// Returns the sender device name.
  String? get name => _name;

  /// Returns the sender device MAC address.
  String? get mac => _mac;

/*-------------------------------Public methods-------------------------------*/

  /// Returns the JSON representation as a [Map] of this [Header] instance.
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
