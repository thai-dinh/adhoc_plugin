import 'package:json_annotation/json_annotation.dart';

import 'constants.dart';
import '../utils/identifier.dart';
import '../utils/utils.dart';

part 'adhoc_device.g.dart';


/// Class representing a generic ad hoc device. It represents a remote device 
/// with  the Wi-Fi Direct, Bluetooth Low Energy, or both technology enabled.
@JsonSerializable()
class AdHocDevice {
  /// Address of the remote device.
  String? address;

  String? _label;
  String? _name;

  late Identifier _mac;
  late int _type;

  /// Creates an [AdHocDevice] object.
  ///
  /// If [label] is given, then it is used as a unique identifier to represent 
  /// the remote device.
  /// 
  /// If [address] is given, then it is either used as an UUID in case of 
  /// Bluetooth Low Energy, or an IPv4 address in case of Wi-Fi Direct.
  /// 
  /// If [name] is given, then it is used to represent the name of the remote
  /// device.
  /// 
  /// If [mac] is given, then it represents the MAC address of the remote device.
  /// 
  /// If [type] is given, then it defines the type of technology used, i.e.,
  /// "0" stands for Wi-Fi Direct and "1" stands for Bluetooth Low Energy.
  AdHocDevice({
    String? label, String? address, String? name, Identifier? mac, int type = -1,
  }) {
    this.address = checkString(address);
    this._label = checkString(label);
    this._name = checkString(name);
    this._mac = mac == null ? Identifier() : mac;
    this._type = type;
  }

  /// Factory constructor that creates an [AdHocDevice] object from a JSON 
  /// representation ([json]).
  factory AdHocDevice.fromJson(Map<String, dynamic> json) => _$AdHocDeviceFromJson(json);

/*------------------------------Getters & Setters-----------------------------*/

  /// Label of this remote node instance.
  String? get label => _label;

  /// Device name of this remote node instance.
  String? get name => _name;

  /// MAC address of this remote node instance.
  Identifier get mac => _mac;

  /// Type of this remote node instance.
  int get type => _type;

/*-------------------------------Public methods-------------------------------*/

  /// Returns the JSON representation as a [Map] of this [AdHocDevice] instance.
  Map<String, dynamic> toJson() => _$AdHocDeviceToJson(this);

  /// Returns a string representation of this remote device's type.
  ///
  /// The type of this instance can be Bluetooth Low Energy (BLE),
  /// Wi-Fi Direct (WIFI), or unknown (UNKNOWN) if the type is not specified.
  String typeAsString() {
    switch (type) {
      case BLE:
        return "BLE";
      case WIFI:
        return "WIFI";
      default:
        return "UNKNOWN";
    }
  }

/*------------------------------Override methods------------------------------*/

  @override
  String toString() {
    return 'AdHocDevice{' +
              'label=$label' +
              ', name=$name' +
              ', mac=$mac' +
              ', address=$address' +
              ', type=${typeAsString()}' +
           '}';
  }
}
