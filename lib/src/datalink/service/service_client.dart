import 'dart:math';

import 'constants.dart';
import 'service.dart';
import '../utils/msg_adhoc.dart';


/// Abstract class defining the client's logic and methods. It aims to serve as 
/// a common interface for the services 'BleClient' and 'WifiClient' classes.
abstract class ServiceClient extends Service {
  static const String TAG = "[ServiceClient]";

  late int _attempts;
  late int _backOffTime;
  late int _timeOut;

  /// Creates a [ServiceClient] object.
  /// 
  /// The debug/verbose mode is set if [verbose] is true.
  /// 
  /// Tries to connect to a remote device in [attempts] times.
  /// 
  /// A connection attempt is said to be a failure if nothing happens after 
  /// [timeOut] ms.
  ServiceClient(
    bool verbose, this._attempts, this._timeOut,
  ) : super(verbose) {
    this._backOffTime = new Random().nextInt(HIGH - LOW) + LOW;
  }

/*------------------------------Getters & Setters-----------------------------*/

  /// Connection attempt time out duration.
  int get timeOut => _timeOut;

  /// Connection attempts.
  int get attempts => _attempts;

  /// Back off time for connection attempts.
  int get backOffTime => _backOffTime *= 2;

/*-------------------------------Public methods-------------------------------*/

  /// Initiates a connection with the remote device.
  void connect();

  /// Cancels the connection with the remote device.
  void disconnect();

  /// Sends a [message] to the remote device.
  void send(MessageAdHoc message);
}
