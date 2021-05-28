import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'constants.dart';
import 'secure_data.dart';
import '../appframework/config.dart';
import '../datalink/service/adhoc_device.dart';
import '../datalink/service/adhoc_event.dart';
import '../datalink/utils/utils.dart';
import '../network/aodv/aodv_manager.dart';
import '../network/datalinkmanager/constants.dart';
import '../network/datalinkmanager/datalink_manager.dart';
import 'package:cryptography/cryptography.dart';
import 'package:ninja_prime/ninja_prime.dart';


/// Class managing the creation and maintenance of a secure group
class SecureGroupController {
  static const TAG = '[SecureGroupController]';

  AodvManager _aodvManager;
  DataLinkManager _datalinkManager;
  Stream<AdHocEvent> _eventStream;
  late String _ownLabel;
  late StreamController<AdHocEvent> _eventCtrl;

  /// Time allowed for joining the group creation process
  int? _expiryTime;
  /// Group member's key share recovered
  int? _recovered;
  /// Order of the finite cyclic group
  BigInt? _p;
  /// Generator of the finite cyclic group of order [_p]
  BigInt? _g;
  /// Private Diffie-Hellman share
  BigInt? _x;
  /// Private key share
  BigInt? _k;
  /// Group key sum value
  BigInt? _groupKeySum;
  BigInt? _groupKeyHash;
  /// Secret group key
  SecretKey? _groupKey;
  ///
  late String? _groupOwner;
  /// Map containing the Diffie-Hellman share of each member
  late HashMap<String, BigInt> _DHShare;
  /// Map containing the member share of each member
  late HashMap<String, BigInt> _memberShare;
  /// Map containing the Chinese Remainder Theorem solution of each member
  late HashMap<String, BigInt> _CRTShare;
  /// List containing the group member label
  late List<String> _memberLabel;

  /// Creates a [SecureGroupController] object.
  /// 
  /// This object is configured according to [config], which contains specific 
  /// configurations.
  SecureGroupController(
    this._aodvManager, this._datalinkManager, this._eventStream, Config config
  ) {
    this._ownLabel = _aodvManager.label;
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

  /// Stream of ad hoc event notifications of lower layers.
  Stream<AdHocEvent> get eventStream => _eventCtrl.stream;

/*-------------------------------Public methods-------------------------------*/

  /// Initiates a secure group creation process
  void createGroup([int? groupId]) {
    // TODO:
    if (true) log(TAG, 'createGroup');

    if (groupId == null)
      groupId = 1;

    _groupOwner = _ownLabel;

    _p = randomPrimeBigInt(256);
    _g = randomPrimeBigInt(128);

    SecureData message = SecureData(
      GroupTag.init.index, [groupId, _groupOwner, _p.toString(), _g.toString()]
    );

    _memberLabel.add(_ownLabel);
    _datalinkManager.broadcastObject(message);

    Timer(Duration(seconds: _expiryTime!), () => _timerExpired(groupId!));
  }


  /// Joins an existing secure group
  void joinSecureGroup() {
    SecureData message = SecureData(GroupTag.join.index, []);
    _datalinkManager.broadcastObject(message);
  }


  /// Leaves an existing secure group
  void leaveSecureGroup() {
    SecureData message = SecureData(GroupTag.leave.index, _memberLabel.first);
    for (final String? label in _memberLabel) {
      if (label! != _ownLabel)
        _aodvManager.sendMessageTo(label, message);
    }

    _p = _g = _x = _k = _groupKeySum = BigInt.zero;
    _groupKey = _groupKeyHash = null;
    _memberLabel.clear();
    _memberShare.clear();
    _DHShare.clear();
    _CRTShare.clear();
  }


  /// Sends a encrypted message to the secure group.
  /// 
  /// The message payload is set to [data] and is encrypted using the group key.
  void sendMessageToGroup(Object? data) async {
    if (true) log(TAG, 'sendMessageToGroup');
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

    for (final String? label in _memberLabel)
      if (label != _ownLabel)
        _aodvManager.sendMessageTo(label!, _data);
  }

/*------------------------------Private methods-------------------------------*/

  /// Initializes the listening process of lower layer streams.
  void _initialize() {
    _eventStream.listen((event) {
      if (event.type == DATA_RECEIVED) {
        _processDataReceived(event);
      }
    });
  }


  /// Computes a Diffie-Hellman share.
  /// 
  /// Returns a integer value as [BigInt] representing y = g^x mod p.
  BigInt _computeDHShare() {
    if (true) log(TAG, '_computeDHShare');
    _x = randomBigInt(_p!.bitLength, max: _p);
    return _g!.modPow(_x!, _p!);
  }

  
  /// Triggers the group key agreement.
  /// 
  /// The agreement process for the group [groupId] starts after the specified 
  /// duration set at initialization by a Config object.
  void _timerExpired(int groupId) {
    if (true) log(TAG, '_timerExpired');
    SecureData message = SecureData(
      GroupTag.list.index, [groupId, _memberLabel]
    );

    for (final String label in _memberLabel) {
      if (label != _ownLabel)
        _aodvManager.sendMessageTo(label, message);
    }

    BigInt y = _computeDHShare();
    _DHShare.putIfAbsent(_ownLabel, () => y);

    message = SecureData(
      GroupTag.share.index, [groupId, y.toString()]
    );

    for (final String label in _memberLabel) {
      if (label != _ownLabel)
        _aodvManager.sendMessageTo(label, message);
    }
  }

  
  /// Computes the Diffie-Hellman secret share.
  /// 
  /// The Diffie-Hellman secret share is computed from [yj] sent by a remote
  /// node identified by [label].
  /// 
  /// Returns an integer value as [BigInt] representing the secret share.
  BigInt _computeMemberShare(String label, BigInt yj) {
    if (true) log(TAG, '_computeMemberShare');
    BigInt mij = yj.modPow(_x!, _p!);
    mij = mij > (_p!~/BigInt.two) ? mij : _p! - mij;
    _memberShare.putIfAbsent(label, () => mij);
    return mij;
  }

  
  /// Solves the CRT system of congruences.
  /// 
  /// The CRT system is solved with the parameters sent by a remote node [label].
  /// 
  /// The public D-H share and secret shared D-H share is set respectively to 
  /// [yj] and [mij].
  /// 
  /// Returns the solution as an integer [BigInt] to the CRT system of 
  /// congruences.
  BigInt _computeCRTShare(String label, BigInt yj, BigInt mij) {
    if (true) log(TAG, '_computeCRTShare');
    BigInt pij, di, _min = _memberShare.values.first;

    // Step 4.
    // Choose p_ij such that gcd(p_ij , m_ij) = 1
    while (true) {
      pij = randomBigInt(_p!.bitLength);
      if (mij.gcd(pij) == BigInt.one)
        break;
    }

    // Step 5.
    // Choose random k_i such that k_i < min(m_ij) , for all j (1 < j < n)
    _memberShare.forEach((label, value) {
      if (value < _min)
        _min = value;
    });

    _min = _min < BigInt.one ? BigInt.one : _min;

    _k = randomBigInt(_min.bitLength, max: _min);
    _recovered = _recovered! + 1;

    // Choose randim d_i such that d_i != k_i
    di = _k!;
    while (_k == di)
      di = randomBigInt(_p!.bitLength);

    // Solve the system of congruences (Chinese Remainder Theorem) using the 
    // Bézout's identity to obtain crt_ij
    List<BigInt> coefficients = _solveBezoutIdentity(mij, pij);
    BigInt crtij = 
      (_k! * coefficients[1] * pij) + (di * coefficients[0] * mij);
    while (crtij < BigInt.zero) {
      crtij += (mij * pij);
      print(crtij);
    }

    print('End computation');

    return crtij;
  }


  /// Solves the Bézout identity.
  /// 
  /// The system parameters is set to [a] and [b].
  /// 
  /// Returns a list of integer value as [BigInt] that represents the solution
  /// of the system.
  List<BigInt> _solveBezoutIdentity(BigInt a, BigInt b) {
    if (true) log(TAG, '_solveBezoutIdentity');
    BigInt R = a, _R = b, U = BigInt.one, _U = BigInt.zero;
    BigInt V = BigInt.zero, _V = BigInt.one;

    while (_R != BigInt.zero) {
      BigInt Q = R~/_R;
      BigInt RS = R, US = U, VS = V;
      R = _R; U = _U; V = _V;
      _R = RS - Q*_R;
      _U = US - Q*_U;
      _V = VS - Q*_V;
    }

    return List.empty(growable: true)..add(U)..add(V);
  }

  
  /// Gets the bytes representation of a [BigInt].
  /// 
  /// The given big int value to represent is given by [bigInt].
  /// 
  /// Returns the bytes representation of the given value.
  Uint8List _toBytes(BigInt bigInt) {
    const BYTE_SIZE = 8;

    ByteData byteData = ByteData((bigInt.bitLength~/BYTE_SIZE) + 1);
    BigInt _bigInt = bigInt;

    for (int i = 1; i <= byteData.lengthInBytes; i++) {
      byteData.setUint8(
        byteData.lengthInBytes - i, _bigInt.toUnsigned(BYTE_SIZE).toInt()
      );

      _bigInt = _bigInt >> BYTE_SIZE;
    }

    return byteData.buffer.asUint8List();
  }

  
  /// Computes the group key.
  /// 
  /// The way the group key is computed is defined by [type].
  void _computeGroupKey(GroupTag type, [String? label]) async {
    if (true) log(TAG, '_computeGroupKey');
    // Step 6.
    // Compute the group key
    switch (type) {
      case GroupTag.init:
        _groupKeySum = _k!;
        for (final String label in _CRTShare.keys) {
          _groupKeySum = 
            _groupKeySum! ^ (_CRTShare[label]! % _memberShare[label]!);
        }
        break;

      case GroupTag.join:
        final Sha256 algorithm = Sha256();
        final Hash hash = await algorithm.hash(_toBytes(_groupKeySum!));
        _groupKeyHash = BigInt.from(hash.bytes.reduce((a, b) => a + b));

        if (label == null) {
          _groupKeySum = _groupKeyHash! ^ _k!;
        } else {
          _groupKeySum = 
            _groupKeyHash! ^ (_CRTShare[label]! % _memberShare[label]!);
        }
        break;

      case GroupTag.leave:
        if (_groupOwner == _ownLabel) {
          _groupKeySum = _groupKeySum! ^ _k!;
        } else {
          _groupKeySum = _groupKeySum! ^ (_CRTShare[label]! % _memberShare[label]!);
        }
        break;

      default:
    }

    print('GroupKey: ${_groupKeySum!.toInt()}');
    _groupKey = SecretKey(_toBytes(_groupKeySum!));
  }


  /// Processes the data received.
  /// 
  /// The data is retrieved from the [event] payload.
  void _processDataReceived(AdHocEvent event) async {
    AdHocDevice sender = (event.payload as List<dynamic>)[0] as AdHocDevice;
    String senderLabel = sender.label!;
    SecureData pdu = SecureData.fromJson(
      (event.payload as List<dynamic>)[1] as Map<String, dynamic>
    );

    if (pdu.type > GroupTag.values.length)
      return;

    GroupTag type = GroupTag.values[pdu.type];
    List<dynamic> payload = pdu.payload as List<dynamic>;
    switch (type) {
        case GroupTag.init:
          int groupId = payload[0] as int;
          if (groupId == 1) {
            _groupOwner = payload[1] as String;

            _p = BigInt.parse(payload[2] as String);
            _g = BigInt.parse(payload[3] as String);

            SecureData msg = SecureData(GroupTag.reply.index, [groupId]);
            _aodvManager.sendMessageTo(senderLabel, msg);
          } else {
            // TODO
          }
          break;

        case GroupTag.reply:
          int groupId = payload[0] as int;
          if (groupId == 1) {
            _memberLabel.add(senderLabel);
          }
          break;

        case GroupTag.list:
          int groupId = payload[0] as int;
          if (groupId == 1) {
            _memberLabel.addAll((payload[1] as List<dynamic>).cast<String>());

            BigInt y = _computeDHShare();
            _DHShare.putIfAbsent(_ownLabel, () => y);

            SecureData msg = SecureData(GroupTag.share.index, [groupId, y.toString()]);
            for (final String label in _memberLabel) {
              if (label != _ownLabel)
                _aodvManager.sendMessageTo(label, msg);
            }
          } else {
            // TODO
          }
          break;

        case GroupTag.share:
          int groupId = payload[0] as int;
          if (groupId == 1) {
            BigInt yj = BigInt.parse(payload[1] as String);
            BigInt mij = _computeMemberShare(senderLabel, yj);
            BigInt crtij = _computeCRTShare(senderLabel, yj, mij);

            _DHShare.putIfAbsent(senderLabel, () => yj);

            SecureData msg = SecureData(
              GroupTag.key.index, 
              [groupId, GroupTag.init.index, crtij.toString()]
            );

            _aodvManager.sendMessageTo(senderLabel, msg);
          } else {
            // TODO
          }
          break;

        case GroupTag.join:
          int groupId = payload[0] as int;
          if (groupId == 1) {
            SecureData msg = SecureData(GroupTag.join_req.index, [groupId, senderLabel]); // Label
            _aodvManager.sendMessageTo(_groupOwner!, msg);
          } else {
            // TODO
          }
          break;
        case GroupTag.join_req:
          int groupId = payload[0] as int;
          if (groupId == 1) {
            _memberLabel.add(payload[1] as String);

            final Sha256 algorithm = Sha256();
            final Hash hash = await algorithm.hash(_toBytes(_groupKeySum!));
            _groupKeyHash = BigInt.from(hash.bytes.reduce((a, b) => a + b));

            List<String> labels = List.empty(growable: true);
            List<String> values = List.empty(growable: true);
            _DHShare.forEach((label, value) {
              labels.add(label);
              values.add(value.toString());
            });

            SecureData msg = SecureData(
              GroupTag.join_rep.index, 
              [groupId, _groupKeyHash.toString(), labels, values]
            ); // Label

            _aodvManager.sendMessageTo(_groupOwner!, msg);
          } else {
            // TODO
          }
          break;
        case GroupTag.join_rep:
          int groupId = payload[0] as int;
          if (payload.length > 3) { // New member
            _groupKeyHash = BigInt.parse(payload[1] as String);

            List<String> labels = (payload[2] as List).cast<String>();
            List<String> values = (payload[3] as List).cast<String>();
            HashMap<String, BigInt> buffer = HashMap();
            for (int i = 0; i < labels.length; i++)
              _DHShare.putIfAbsent(labels[i], () => BigInt.parse(values[i]));

            BigInt y = _computeDHShare();
            _DHShare.putIfAbsent(_ownLabel, () => y);
            _DHShare.addAll(buffer);

            for (final String label in _memberLabel) {
              if (label != _ownLabel) {
                BigInt mij = _computeMemberShare(label, _DHShare[label]!);
                BigInt crtij = _computeCRTShare(label, _DHShare[label]!, mij);

                SecureData msg = SecureData(
                  GroupTag.join_rep.index, 
                  [groupId, y.toString(), crtij.toString()]
                ); // nonce

                _aodvManager.sendMessageTo(label, msg);
              }
            }

            _computeGroupKey(GroupTag.join, null);
          } else { // Old member
            BigInt yj = BigInt.parse(payload[1] as String);
            BigInt mij = _computeMemberShare(senderLabel, yj);
            BigInt crtij = BigInt.parse(payload[2] as String);

            _DHShare.putIfAbsent(senderLabel, () => yj);
            _memberShare.putIfAbsent(senderLabel, () => mij);
            _CRTShare.putIfAbsent(senderLabel, () => crtij);

            _computeGroupKey(GroupTag.join, senderLabel);
          }
          break;

        case GroupTag.leave:
          int groupId = payload[0] as int;
          if (_groupOwner == _ownLabel) {
            _memberLabel.remove(payload[1] as String);

            for (String label in _memberLabel) {
              BigInt yj = _DHShare[label]!;
              BigInt mij = _memberShare[label]!;
              BigInt crtij = _computeCRTShare(label, yj, mij);

              SecureData msg = SecureData(
                GroupTag.leave.index, [groupId, crtij.toString()]
              ); // nonce

              _aodvManager.sendMessageTo(label, msg);
            }
          } else {
            if (payload[1] is String) {
              SecureData msg = SecureData(
                GroupTag.leave.index, [groupId, senderLabel]
              ); // nonce

              _aodvManager.sendMessageTo(_groupOwner!, msg);
            } else {
              _CRTShare[_groupOwner!] = BigInt.parse(payload[1] as String);

              _computeGroupKey(GroupTag.leave, _groupOwner);
            }
          }
          break;

        case GroupTag.key:
          int groupId = payload[0] as int;
          if (groupId == 1) {
            GroupTag tag = GroupTag.values[payload[1] as int];
            BigInt crtji = BigInt.parse(payload[2] as String);

            _CRTShare.putIfAbsent(senderLabel, () => crtji);
            _recovered = _recovered! + 1;

            if (_recovered == _memberLabel.length) {
              _computeGroupKey(tag);
            }
          } else {
            // TODO
          }
          break;

      default:
    }
  }
}
