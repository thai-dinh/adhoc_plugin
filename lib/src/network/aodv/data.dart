import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'data.g.dart';


@JsonSerializable()
class Data {
  String _destIpAddress;
  Object _payload;

  Data({@required String destIpAddress, @required Object payload}) {
    this._destIpAddress = destIpAddress;
    this._payload = payload;
  }

/*------------------------------Getters & Setters-----------------------------*/

  String get destIpAddress => _destIpAddress;

  Object get payload => _payload;

  set destIpAddress(String destIpAddress) => _destIpAddress = destIpAddress;

  set payload(Object payload) => _payload = payload;

/*------------------------------Override methods------------------------------*/

  @override
  String toString() {
    return 'Data{' +
            'destIpAddress=' + _destIpAddress +
            ', payload=' + _payload.toString() +
          '}';
  }
}