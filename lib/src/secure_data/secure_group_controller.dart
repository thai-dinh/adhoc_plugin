import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:adhoc_plugin/src/appframework/config.dart';
import 'package:adhoc_plugin/src/datalink/service/adhoc_device.dart';
import 'package:adhoc_plugin/src/datalink/service/adhoc_event.dart';
import 'package:adhoc_plugin/src/network/aodv/aodv_manager.dart';
import 'package:adhoc_plugin/src/network/aodv/constants.dart';
import 'package:adhoc_plugin/src/network/datalinkmanager/constants.dart';
import 'package:adhoc_plugin/src/network/datalinkmanager/datalink_manager.dart';
import 'package:adhoc_plugin/src/secure_data/constants.dart';
import 'package:adhoc_plugin/src/secure_data/secure_data.dart';
import 'package:cryptography/cryptography.dart';
import 'package:ninja_prime/ninja_prime.dart';


/// Class managing the creation and maintenance of a secure group
class SecureGroupController {
  AodvManager? _aodvManager;
  DataLinkManager? _datalinkManager;
  Stream<AdHocEvent> _eventStream;
  String? _ownLabel;

  /// Time allowed for joining the group creation process
  int? _expiryTime;
  /// Order of the finite cyclic group
  int? _p;
  /// Generator of the finite cyclic group of order [_p]
  int? _g;
  /// Group member's CRT share received
  int? _computed;
  /// Secret group key
  SecretKey? _groupKey;
  /// Map containing the Diffie-Hellman share of each member
  late HashMap<String?, int> _DHShares;
  /// Map containing the Chinese Remainder Theorem solution of each member
  late HashMap<String?, int> _CRTShares;
  /// List containing members label
  late List<String?> _membersLabel;

  /// Default constructor
  SecureGroupController(this._aodvManager, this._datalinkManager, this._eventStream, Config config) {
    this._ownLabel = _aodvManager!.label;
    this._expiryTime = config.expiryTime;
    this._computed = 0;
    this._DHShares = HashMap();
    this._CRTShares = HashMap();
    this._membersLabel = List.empty(growable: true);
    this._initialize();
  }

/*-------------------------------Public methods-------------------------------*/

  /// Initiates a secure group creation process
  void createSecureGroup() {
    SecureData message = SecureData(
      GROUP_REQUEST, [_p = 17, _g = 7] // TODO: generate primes (BigInt)
    );

    _datalinkManager!.broadcastObject(message);
    _membersLabel.add(_ownLabel);

    Timer(Duration(seconds: _expiryTime!), _createSecureGroupExpired);
  }

  /// Join an existing secure group
  void joinSecureGroup() {
    
  }

  /// Leave an existing secure group
  void leaveSecureGroup() {
    
  }

  void sendMessageToGroup(Object? data) {
    // Encrypt data
    SecureData _data = SecureData(GROUP_MESSAGE, data);

    for (final String? label in _membersLabel)
      _aodvManager!.sendMessageTo(_data, label);
  }

/*------------------------------Private methods-------------------------------*/

  void _initialize() {
    _eventStream.listen((event) {
      if (event.type == DATA_RECEIVED) {
        _processDataReceived(event);
      }
    });
  }

  void _createSecureGroupExpired() {
    _DHShares.putIfAbsent(_ownLabel, () => _computeDHShare()); // DH_L
    SecureData message = SecureData(GROUP_FORMATION_REQ, [LEADER, _membersLabel, _DHShares[_ownLabel]]);

    for (final String? label in _membersLabel)
      if (label != _ownLabel)
        _aodvManager!.sendMessageTo(message, label);
  }

  int _computeDHShare() {
    return pow(_g!, Random().nextInt(512)).toInt() % _p!;
  }

  int _computeCRTShare(String label, int yj) {
    int? pj, keyShare, once;

    _computed = _computed! + 1;

    /* Step 3 */
    int mj = (pow(yj, _DHShares[_ownLabel]!) as int) % _p!;
    mj = mj > _p!/2 ? mj : _p! - mj;
    _DHShares[label] = mj;

    /* Step 4 */
    while (true) {
      if (mj.gcd(pj = Random().nextInt(2048)) == 1)
        break;
    }

    /* Step 5 */
    keyShare = Random().nextInt(MAX_SINT_VAL);
    _CRTShares[_ownLabel] = keyShare;

    once = keyShare;
    while (keyShare == once)
      once = Random().nextInt(MAX_SINT_VAL);

    List<int?> coefficients = _solveBezoutIdentity(mj, pj);
    int CRTSharej = (keyShare * coefficients[1]! * pj) + (once! * coefficients[0]! * mj);
    while (CRTSharej < 0)
      CRTSharej += (mj * pj);

    return CRTSharej;
  }

  void _computeGroupKey() async {
    /* Step 6 */
    List<int> gk = List.empty(growable: true)..add(_CRTShares[_ownLabel]!);
    for (final String? label in _CRTShares.keys) {
      if (label != _ownLabel)
        gk.add(_CRTShares[label]! % _DHShares[label]!);
    }

    _groupKey = SecretKey(gk);
  }

  List<int?> _solveBezoutIdentity(int? a, int? b) {
    int? R = a, _R = b, U = 1, _U = 0, V = 0, _V = 1;

    while (_R != 0) {
      int Q = R!~/_R!;
      int? RS = R, US = U, VS = V;
      R = _R; U = _U; V = _V;
      _R = RS - Q*_R;
      _U = US! - Q*_U!;
      _V = VS! - Q*_V!;
    }

    return List.empty(growable: true)..add(U)..add(V);
  }

  void _processDataReceived(AdHocEvent event) {
    AdHocDevice sender = (event.payload as List<dynamic>)[0] as AdHocDevice;
    SecureData pdu = SecureData.fromJson((event.payload as List<dynamic>)[1] as Map<String, dynamic>);

    switch (pdu.type) {
      case GROUP_REQUEST:
        _datalinkManager!.broadcastObjectExcept(pdu, sender.label);

        _p = (pdu.payload as List<dynamic>)[0] as int;
        _g = (pdu.payload as List<dynamic>)[1] as int;

        SecureData reply = SecureData(GROUP_REPLY, []);
        _aodvManager!.sendMessageTo(reply, sender.label);
        break;

      case GROUP_REPLY:
        _membersLabel.add(sender.label);
        break;

      case GROUP_FORMATION_REQ:
        List<dynamic> data = pdu.payload as List<dynamic>;

        /* Step 1. */
        if (data[0] == LEADER) {
          _membersLabel.addAll((data[1] as List<dynamic>).cast<String>());

          _DHShares.putIfAbsent(_ownLabel, () => _computeDHShare()); // DH_M
          _DHShares.putIfAbsent(sender.label, () => data[2] as int); // DH_L

          for (final String? label in _membersLabel) {
            if (label != _ownLabel) {
              /* Step 2. */
              SecureData reply = SecureData(GROUP_FORMATION_REQ, [MEMBER, _DHShares[_ownLabel]]);
              _aodvManager!.sendMessageTo(reply, label);
            }
          }

          // CRT_M->L
          SecureData reply = SecureData(GROUP_FORMATION_REP, _computeCRTShare(sender.label!, _DHShares[sender.label]!));
          _aodvManager!.sendMessageTo(reply, sender.label);
        } else {
          _DHShares.putIfAbsent(sender.label, () => data[1] as int); // DH_M

          SecureData reply = SecureData(GROUP_FORMATION_REP, _computeCRTShare(sender.label!, data[1])); // CRT_L->M
          _aodvManager!.sendMessageTo(reply, sender.label);
        }
        break;

      case GROUP_FORMATION_REP:
        // CRT_M->L
        _CRTShares.putIfAbsent(sender.label, () => pdu.payload as int);
        _computed = _computed! + 1;

        if (_computed == _CRTShares.length) 
          _computeGroupKey();
        break;

      case GROUP_JOIN:


        break;

      case GROUP_LEAVE:
        

        break;

      case GROUP_MESSAGE:

        break;

      default:
    }
  }
}
