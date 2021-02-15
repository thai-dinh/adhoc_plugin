import 'package:adhoclibrary/src/datalink/service/service.dart';
import 'package:adhoclibrary/src/datalink/utils/utils.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'adhoc_device.g.dart';


@JsonSerializable()
class AdHocDevice {
  bool directedConnected;
  String label;
  String name;
  String mac;
  String address;
  int type;

  AdHocDevice({
    @required String name, @required this.type, @required this.mac,
    this.address = '', this.label = '', this.directedConnected = false
  }) {
    this.label = Utils.checkString(label);
    this.name = Utils.checkString(name);
    this.mac = Utils.checkString(mac);
    this.address = Utils.checkString(address);
    this.type = type;
  }

  factory AdHocDevice.fromJson(Map<String, dynamic> json) 
    => _$AdHocDeviceFromJson(json);

  Map<String, dynamic> toJson() => _$AdHocDeviceToJson(this);

  String typeAsString() {
    switch (type) {
      case Service.BLUETOOTHLE:
        return "BluetoothLE";
      case Service.WIFI:
        return "Wifi";
      default:
        return "UNKNOWN";
    }
  }

  @override
  String toString() {
    return 'AdHocDevice{' +
              'label=' + label +
              ', name=' + name +
              ', mac=' + mac +
              ', address=' + address +
              ', type=' + type.toString() +
              ', directedConnected=' + directedConnected.toString() +
           '}';
  }
}
