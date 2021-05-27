/// Class allowing to have a distinct MAC address for BLE and Wi-Fi enabled
/// simultaneously.
/// 
/// It allows to identify a device that owns two different MAC addresses.
class Identifier {
  late String ble;
  late String wifi;

  /// Creates a [Identifier] object.
  /// 
  /// If [ble] is given, then it defines the MAC address using when dealing with
  /// Bluetooth Low Energy.
  /// 
  /// If [wifi] is given, then it defines the MAC address using when dealing with
  /// Wi-Fi Direct.
  Identifier({String ble = '', String wifi = ''}) {
    this.ble = ble;
    this.wifi = wifi;
  }

  /// Creates a [Identifier] object from a JSON representation.
  /// 
  /// Factory constructor that creates a [Identifier] based on the 
  /// information given by [json].
  factory Identifier.fromJson(Map<String, dynamic> json) {
    return Identifier(ble: json['ble'] as String, wifi: json['wifi'] as String);
  }

/*-------------------------------Public methods-------------------------------*/

  /// Returns the JSON representation as a [Map] of this [Identifier] instance.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{ 'ble': ble, 'wifi': wifi };
  }

/*------------------------------Override methods------------------------------*/

  @override
  String toString() {
    return 'Identifier{' +
              'ble=$ble, ' +
              'wifi=$wifi' +
           '}';
  }
}