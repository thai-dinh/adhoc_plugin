import '../service/constants.dart';
import '../utils/utils.dart';

import 'package:json_annotation/json_annotation.dart';

part 'adhoc_device.g.dart';


/// Object representing an ad hoc device in general. It can have Wifi, 
/// Bluetooth Low Energy, or both enabled.
@JsonSerializable()
class AdHocDevice {
  String? address;

  String? _label;
  String? _name;
  String? _mac;

  late int _type;

  /// Creates an [AdHocDevice] object.
  ///
  /// If [label] is given, it is used to identify the remote device.
  /// 
  /// If [address] is given, it is either an UUID in case of Bluetooth Low 
  /// Energy, or an IPv4 address in case of Wifi P2P.
  AdHocDevice({
    String? label, String? address, String? name, String? mac, int type = -1,
  }) {
    this.address = checkString(address);
    this._label = checkString(label);
    this._name = checkString(name);
    this._mac = mac;
    this._type = type;
  }

  /// Creates an [AdHocDevice] object from a JSON representation.
  /// 
  /// Factory constructor that creates a [AdHocDevice] based on the information 
  /// given by [json].
  factory AdHocDevice.fromJson(Map<String, dynamic> json) => _$AdHocDeviceFromJson(json);

/*------------------------------Getters & Setters-----------------------------*/

  /// Returns the label of this remote node instance.
  String? get label => _label;

  /// Returns the name of this remote node instance.
  String? get name => _name;

  /// Returns the MAC address of this remote node instance.
  String? get mac => _mac;

  /// Returns the type of this remote node instance.
  int get type => _type;

/*-------------------------------Public methods-------------------------------*/

  /// Returns the JSON representation as a [Map] of this [AdHocDevice] instance.
  Map<String, dynamic> toJson() => _$AdHocDeviceToJson(this);

  /// Returns a [String] representation of this remote device's type
  ///
  /// The type of this instance can be Bluetooth Low Energy (Ble),
  /// Wifi P2P (Wifi), or unknown (UNKNOWN) if the type is not specified.
  String typeAsString() {
    switch (type) {
      case BLE:
        return "Ble";
      case WIFI:
        return "Wifi";
      default:
        return "UNKNOWN";
    }
  }

/*------------------------------Override methods------------------------------*/

  @override
  String toString() {
    return 'AdHocDevice{' +
              'label=$_label' +
              ', name=$_name' +
              ', mac=$_mac' +
              ', address=$address' +
              ', type=${typeAsString()}' +
           '}';
  }
}
