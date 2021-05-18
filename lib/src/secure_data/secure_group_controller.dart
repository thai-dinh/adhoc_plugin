import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

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
  late StreamController<AdHocEvent> _eventCtrl;

  /// Time allowed for joining the group creation process
  int? _expiryTime;
  /// Order of the finite cyclic group
  int? _p;
  /// Generator of the finite cyclic group of order [_p]
  int? _g;
  /// Private Diffie-Hellman share
  int? _x;
  /// Private key share
  int? _k;
  /// Group member's key share recovered
  int? _recovered;
  /// Group key sum value
  int? _groupKeySum;
  /// Secret group key
  SecretKey? _groupKey;
  /// Map containing the Diffie-Hellman share of each member
  late HashMap<String, int> _DHShare;
  /// Map containing the member share of each member
  late HashMap<String, int> _memberShare;
  /// Map containing the Chinese Remainder Theorem solution of each member
  late HashMap<String, int> _CRTShare;
  /// List containing the group member label
  late List<String> _memberLabel;

  /// Default constructor
  SecureGroupController(this._aodvManager, this._datalinkManager, this._eventStream, Config config) {
    this._ownLabel = _aodvManager!.label;
    this._eventCtrl = StreamController<AdHocEvent>.broadcast();
    this._expiryTime = config.expiryTime;
    this._recovered = 0;
    this._DHShare = HashMap();
    this._memberShare = HashMap();
    this._CRTShare = HashMap();
    this._memberLabel = List.empty(growable: true);
    this._initialize();
  }

/*------------------------------Getters & Setters-----------------------------*/

  Stream<AdHocEvent> get eventStream => _eventCtrl.stream;

/*-------------------------------Public methods-------------------------------*/

  /// Initiates a secure group creation process
  void createSecureGroup() {
    SecureData message = SecureData(
      GROUP_REQUEST, [_p = 17, _g = 7] // TODO: generate primes (BigInt)
    );

    _datalinkManager!.broadcastObject(message);
    _memberLabel.add(_ownLabel!);

    Timer(Duration(seconds: _expiryTime!), _createSecureGroupExpired);
  }

  /// Join an existing secure group
  void joinSecureGroup() {
    
  }

  /// Leave an existing secure group
  void leaveSecureGroup() {
    
  }

  void sendMessageToGroup(Object? data) async {
    // Encrypt data
    final AesCbc algorithm = AesCbc.with128bits(
      macAlgorithm: Hmac.sha256()
    );

    final SecretBox secretBox = await algorithm.encrypt(
      Utf8Encoder().convert(JsonCodec().encode(data)), 
      secretKey: _groupKey!,
    );

    List<List<int>> encryptedData = List.empty(growable: true);
    encryptedData.add(secretBox.cipherText);
    encryptedData.add(secretBox.nonce);
    encryptedData.add(secretBox.mac.bytes);

    SecureData _data = SecureData(GROUP_MESSAGE, encryptedData);

    for (final String label in _memberLabel)
      if (label != _ownLabel)
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

  int _computeDHShare() {
    _x = Random().nextInt(_p!);
    return pow(_g!, _x!).toInt() % _p!;
  }

  void _createSecureGroupExpired() {
    _DHShare.putIfAbsent(_ownLabel!, () => _computeDHShare());
    SecureData message = SecureData(GROUP_FORMATION_REQ, [LEADER, _memberLabel, _DHShare[_ownLabel]!]);
    for (final String label in _memberLabel)
      if (label != _ownLabel)
        _aodvManager!.sendMessageTo(message, label);
  }

  int _computeMemberShare(String label, int yj) {
    /* Step 3 */
    int mij = pow(yj, _x!).toInt() % _p!;
    mij = mij > (_p!/2).ceil() ? mij : _p! - mij;
    _memberShare.putIfAbsent(label, () => mij);
    return mij;
  }

  int _computeCRTShare(String label, int yj, int mij) {
    int? pij, di, _min = MAX_SINT_VAL;

    /* Step 4 */
    while (true) {
      pij = Random().nextInt(2048);
      if (mij.gcd(pij) == 1)
        break;
    }

    /* Step 5 */
    for (final int value in _memberShare.values)
      _min = min(_min!, value);
    _min = max(_min!, 1);

    _k = Random().nextInt(_min);

    di = _k;
    while (_k == di)
      di = Random().nextInt(MAX_SINT_VAL);

    List<int?> coefficients = _solveBezoutIdentity(mij, pij);
    int crtij = (_k! * coefficients[1]! * pij) + (di! * coefficients[0]! * mij);
    while (crtij < 0)
      crtij += (mij * pij);

    return crtij;
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

  void _computeGroupKey(int type, [int? kj]) async {
    /* Step 6 */
    _groupKeySum = _k!;
    switch (type) {
      case FORMATION:
        for (final String? label in _CRTShare.keys)
          _groupKeySum = _groupKeySum! + (_CRTShare[label]! % _memberShare[label]!);
        break;

      case JOIN:
        final Sha256 algorithm = Sha256();
        final Hash hash = await algorithm.hash([_groupKeySum!]);
        _groupKeySum = _groupKeySum! + hash.bytes.reduce((a, b) => a + b);
        break;

      case LEAVE:
        _groupKeySum = _groupKeySum! + kj!;
        break;

      default:
    }

    List<int> key = List.empty(growable: true);
    for (int i = 0; i < 16; i ++)
      key.add(_groupKeySum!);

    print('GroupKey: $_groupKeySum');
    _groupKey = SecretKey(key);
  }

  void _processDataReceived(AdHocEvent event) async {
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
        _memberLabel.add(sender.label!);
        break;

      case GROUP_FORMATION_REQ:
        List<dynamic> data = pdu.payload as List<dynamic>;

        /* Step 1. */
        if (data[0] == LEADER) {
          _DHShare.putIfAbsent(_ownLabel!, () => _computeDHShare());
          _DHShare.putIfAbsent(sender.label!, () => data[2] as int);
          _memberLabel.addAll((data[1] as List<dynamic>).cast<String>());

          for (final String label in _memberLabel) {
            if (label != _ownLabel) {
              /* Step 2. */
              SecureData reply = SecureData(GROUP_FORMATION_REQ, [MEMBER, _DHShare[_ownLabel]]);
              _aodvManager!.sendMessageTo(reply, label);
            }
          }

          SecureData reply = SecureData(
            GROUP_FORMATION_REP, 
            _computeCRTShare(
              sender.label!, 
              _DHShare[sender.label!]!, 
              _computeMemberShare(sender.label!, _DHShare[sender.label!]!)
            )
          );
          _aodvManager!.sendMessageTo(reply, sender.label);
        } else {
          _DHShare.putIfAbsent(sender.label!, () => data[1] as int);
          SecureData reply = SecureData(
            GROUP_FORMATION_REP,
            _computeCRTShare(sender.label!, data[1] as int, _computeMemberShare(sender.label!, data[1] as int))
          );
          _aodvManager!.sendMessageTo(reply, sender.label);
        }
        break;

      case GROUP_FORMATION_REP:
        _CRTShare.putIfAbsent(sender.label!, () => pdu.payload as int);
        _recovered = _recovered! + 1;
        if (_recovered == _CRTShare.length) 
          _computeGroupKey(FORMATION);
        break;

      case GROUP_JOIN_REQ:
        _memberLabel.add(sender.label!);
        final Sha256 algorithm = Sha256();
        final Hash hash = await algorithm.hash([_groupKeySum!]);
        SecureData message = SecureData(
          GROUP_JOIN_REP, [REQUEST, _memberLabel, hash.bytes.reduce((a, b) => a + b), _DHShare]
        );

        _aodvManager!.sendMessageTo(message, sender.label!);
        break;

      case GROUP_JOIN_REP:
        List<dynamic> data = pdu.payload as List<dynamic>;

        if (data[0] == REQUEST) {
          _memberLabel.addAll(data[1]);
          _groupKeySum = data[2];

          (data[3] as Map<dynamic, dynamic>).cast<String, int>().forEach((key, value) {
            _DHShare.putIfAbsent(key, () => value);
          });

          for (final String label in _memberLabel) {
            if (label != _ownLabel) {
              SecureData message = SecureData(GROUP_JOIN_REP, [REPLY, _computeDHShare()]);
              _aodvManager!.sendMessageTo(message, label);
              SecureData reply = SecureData(GROUP_FORMATION_REP, [MEMBER, _computeCRTShare(label, _DHShare[label]!, _computeMemberShare(label, _DHShare[label]!)), true]);
              _aodvManager!.sendMessageTo(reply, label);
            }
          }
        } else {
          _memberShare.putIfAbsent(sender.label!, () => _computeMemberShare(sender.label!, data[1]));
          // compute key when ?
        }
        break;

      case GROUP_LEAVE_REQ:

        break;

      case GROUP_LEAVE_REP:

        break;

      case GROUP_MESSAGE:
        List<dynamic> data = pdu.payload as List<dynamic>;

        final AesCbc algorithm = AesCbc.with128bits(
          macAlgorithm: Hmac.sha256()
        );

        final Uint8List decrypted = Uint8List.fromList(
          await algorithm.decrypt(
            SecretBox(
              (data[0] as List<dynamic>).cast<int>(),
              nonce: (data[1] as List<dynamic>).cast<int>(), 
              mac: Mac((data[2] as List<dynamic>).cast<int>()),
            ),
            secretKey: _groupKey!,
          ),
        );

        dynamic _data = JsonCodec().decode(Utf8Decoder().convert(decrypted));
        print(data);
        _eventCtrl.add(AdHocEvent(DATA_RECEIVED, [sender, _data]));
        break;

      default:
    }
  }
}
