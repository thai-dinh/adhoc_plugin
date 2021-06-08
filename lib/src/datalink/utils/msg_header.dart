import 'package:adhoc_plugin/src/datalink/utils/identifier.dart';
import 'package:adhoc_plugin/src/datalink/utils/utils.dart';
import 'package:json_annotation/json_annotation.dart';

part 'msg_header.g.dart';

/// Class representing the header structure of messages exchanged by
/// applications using the plugin.
@JsonSerializable()
class Header {
  String? _name;

  late Identifier _mac;
  late String _label;
  late int messageType;

  int? seqNum;
  String? address;
  int? deviceType;

  /// Creates a [Header] object.
  ///
  /// [seqNum] is needed to filter the data sent twice when using Bluetooth LE,
  /// which can be observed. More information can be found at
  /// https://www.forward.com.au/pfod/BLE/BLEProblems/index.html.
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
    required int messageType, required String label, int? seqNum, String? name,
    String? address, Identifier? mac, int? deviceType
  }) {
    this.address = address;
    this.deviceType = deviceType;
    this.messageType = messageType;
    this.seqNum = seqNum ?? 0;
    _label = checkString(label);
    _name = checkString(name);
    _mac = mac ?? Identifier();
  }

  /// Creates a [Header] object from a JSON representation.
  ///
  /// Factory constructor that constructs a [Header] based on the information
  /// given by [json].
  factory Header.fromJson(Map<String, dynamic> json) => _$HeaderFromJson(json);

/*------------------------------Getters & Setters-----------------------------*/

  /// Returns the sender label.
  String get label => _label;

  /// Returns the sender device name.
  String? get name => _name;

  /// Returns the sender device MAC address.
  Identifier get mac => _mac;

/*-------------------------------Public methods-------------------------------*/

  /// Returns the JSON representation as a [Map] of this [Header] instance.
  Map<String, dynamic> toJson() => _$HeaderToJson(this);

/*------------------------------Override methods------------------------------*/

  @override
  String toString() {
    return 'Header{' +
        'messageType=$messageType' +
        ', label=$_label' +
        ', name=$_name' +
        ', address=$address' +
        ', mac=$_mac' +
        ', deviceType=$deviceType' +
        ', seqNum=$seqNum' +
        '}';
  }
}
