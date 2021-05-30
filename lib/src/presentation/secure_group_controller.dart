import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:ninja_prime/ninja_prime.dart';

import 'constants.dart';
import 'secure_data.dart';
import '../appframework/config.dart';
import '../datalink/service/adhoc_device.dart';
import '../datalink/service/adhoc_event.dart';
import '../network/aodv/aodv_manager.dart';
import '../network/datalinkmanager/constants.dart';
import '../network/datalinkmanager/datalink_manager.dart';


/// Class managing the creation and maintenance of a secure group
class SecureGroupController {
  AodvManager _aodvManager;
  DataLinkManager _datalinkManager;
  Stream<AdHocEvent> _eventStream;
  late String _ownLabel;
  late StreamController<AdHocEvent> _eventCtrl;

  /// Time allowed for joining the group creation process
  int? _expiryTime;
  /// Order of the finite cyclic group
  BigInt? _p;
  /// Generator of the finite cyclic group of order [_p]
  BigInt? _g;
  /// Private Diffie-Hellman share
  BigInt? _x;
  /// Private key share
  BigInt? _k;
  /// Secret group key
  SecretKey? _groupKey;
  /// State of secure group
  late bool _isFormationOn;
  /// Group member's key share recovered
  late int _recovered;
  /// Label of the group initiator/owner
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
    this._isFormationOn = false;
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
  void createGroup() {
    if (_isFormationOn)
      return;

    _isFormationOn = true;

    _groupOwner = _ownLabel;

    _p = randomPrimeBigInt(128);
    _g = randomPrimeBigInt(32);

    SecureData message = SecureData(
      GroupTag.init.index, [_groupOwner, _p.toString(), _g.toString()]
    );

    _memberLabel.add(_ownLabel);
    _datalinkManager.broadcastObject(message);

    Timer(Duration(seconds: _expiryTime!), _timerExpired);
  }


  /// Joins an existing secure group
  void joinSecureGroup() {
    if (!_isFormationOn)
      return;

    SecureData msg = SecureData(GroupTag.join.index, []);
    _datalinkManager.broadcastObject(msg);
  }


  /// Leaves an existing secure group
  void leaveSecureGroup() {
    if (!_isFormationOn)
      return;

    SecureData msg = SecureData(GroupTag.leave.index, []);
    _aodvManager.sendMessageTo(_groupOwner!, msg);

    _p = _g = _x = _k = BigInt.zero;
    _groupKey = null;
    _memberLabel.clear();
    _memberShare.clear();
    _DHShare.clear();
    _CRTShare.clear();
    _isFormationOn = false;
  }


  /// Sends a encrypted message to the secure group.
  /// 
  /// The message payload is set to [data] and is encrypted using the group key.
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
    _x = randomBigInt(_p!.bitLength, max: _p);
    return _g!.modPow(_x!, _p!);
  }

  
  /// Triggers the start of the group key agreement.
  void _timerExpired() {
    SecureData message = SecureData(GroupTag.list.index, [_memberLabel]);

    for (final String label in _memberLabel) {
      if (label != _ownLabel)
        _aodvManager.sendMessageTo(label, message);
    }

    BigInt y = _computeDHShare();
    _DHShare.putIfAbsent(_ownLabel, () => y);

    message = SecureData(GroupTag.share.index, [y.toString()]);

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
    late BigInt di;
    BigInt pij, _min = _memberShare.values.first;

    // Choose p_ij such that gcd(p_ij , m_ij) = 1
    while (true) {
      pij = randomBigInt(_p!.bitLength);
      if (mij.gcd(pij) == BigInt.one)
        break;
    }

    if (_k == null) {
      // Choose random k_i such that k_i < min(m_ij) , for all j (1 < j < n)
      _memberShare.forEach((label, value) {
        if (value < _min)
          _min = value;
      });

      _min = _min < BigInt.one ? BigInt.one : _min;

      _k = randomBigInt(_min.bitLength, max: _min);
      _recovered += 1;

      // Choose randim d_i such that d_i != k_i
      di = _k!;
      while (_k == di)
        di = randomBigInt(_p!.bitLength);
    }

    // Solve the system of congruences (Chinese Remainder Theorem) using the 
    // Bézout's identity to obtain crt_ij
    List<BigInt> coefficients = _solveBezoutIdentity(mij, pij);
    BigInt crtij = 
      (_k! * coefficients[1] * pij) + (di * coefficients[0] * mij);
    if (crtij < BigInt.zero)
      crtij % (mij * pij);

    return crtij;
  }


  /// Solves the Bézout identity.
  /// 
  /// The system parameters is set to [a] and [b].
  /// 
  /// Returns a list of integer value as [BigInt] that represents the solution
  /// of the system.
  List<BigInt> _solveBezoutIdentity(BigInt a, BigInt b) {
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

  
  /// Computes a hash of the group key.
  Future<BigInt> _computeGroupKeyHash() async {
    final Hash hash = await Sha256().hash(await _groupKey!.extractBytes());
    return BigInt.from(hash.bytes.reduce((a, b) => a + b));
  }

  /// Computes the group key.
  /// 
  /// The way the group key is computed is defined by [type].
  void _computeGroupKey(GroupTag type, [String? label]) async {
    BigInt groupKeySum = BigInt.zero;
    BigInt groupKeyHash = BigInt.zero;

    switch (type) {
      case GroupTag.init:
        groupKeySum += _k!;
        for (final String label in _CRTShare.keys)
          groupKeySum ^= (_CRTShare[label]! % _memberShare[label]!);
        break;

      case GroupTag.join:
        groupKeyHash = await _computeGroupKeyHash();

        if (label == null) {
          groupKeySum = groupKeyHash ^ _k!;
        } else {
          groupKeySum = groupKeyHash ^ (_CRTShare[label]! % _memberShare[label]!);
        }
        break;

      case GroupTag.leave:
        if (_groupOwner == _ownLabel) {
          groupKeySum ^= _k!;
        } else {
          groupKeySum ^= (_CRTShare[_groupOwner]! % _memberShare[_groupOwner]!);
        }
        break;

      default:
    }

    print('GroupKey: ${groupKeySum.toInt()}');
    _groupKey = SecretKey(_toBytes(groupKeySum));
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
          // Store group owner label
          _groupOwner = payload[0] as String;
          // Store Diffie-Hellman parameters
          _p = BigInt.parse(payload[1] as String);
          _g = BigInt.parse(payload[2] as String);
          // Reply to the group formation
          SecureData msg = SecureData(GroupTag.reply.index, []);
          _aodvManager.sendMessageTo(senderLabel, msg);
          break;

        case GroupTag.reply:
          // Add member to list of group member
          _memberLabel.add(senderLabel);
          break;

        case GroupTag.list:
          // Get all the label of the group member
          _memberLabel.addAll((payload[0] as List<dynamic>).cast<String>());

          // Compute own public Diffie-Hellman share
          BigInt y = _computeDHShare();
          _DHShare.putIfAbsent(_ownLabel, () => y);

          // Broadcast it to group member
          SecureData msg = SecureData(GroupTag.share.index, [y.toString()]);
          for (final String label in _memberLabel) {
            if (label != _ownLabel)
              _aodvManager.sendMessageTo(label, msg);
          }
          break;

        case GroupTag.share:
          // Store the public Diffie-Hellman share of group memeber
          BigInt yj = BigInt.parse(payload[0] as String);
          _DHShare.putIfAbsent(senderLabel, () => yj);

          // Once received all, solve the CRT system of congruence for each
          // group member
          if (_DHShare.length == _memberLabel.length) {
            for (String label in _memberLabel) {
              yj = _DHShare[label]!;

              BigInt mij = _computeMemberShare(senderLabel, yj);
              BigInt crtij = _computeCRTShare(senderLabel, yj, mij);

              SecureData msg = SecureData(
                GroupTag.key.index, [GroupTag.init.index, crtij.toString()]
              );

              _aodvManager.sendMessageTo(senderLabel, msg);
            }
          }
          break;

        case GroupTag.key:
          // Store the solution of the CRT system of congruence
          GroupTag tag = GroupTag.values[payload[0] as int];
          BigInt crtji = BigInt.parse(payload[1] as String);
          _CRTShare.putIfAbsent(senderLabel, () => crtji);
          _recovered += 1;

          // Compute the group key
          if (_recovered == _memberLabel.length)
            _computeGroupKey(tag);
          break;

        case GroupTag.join:
          // Send the group join request to the group owner
          SecureData msg = SecureData(GroupTag.join_req.index, [senderLabel]);
          _aodvManager.sendMessageTo(_groupOwner!, msg);
          break;

        case GroupTag.join_req:
          // Group owner responds to the group join request received
          String joiningMember = payload[0] as String;
          _memberLabel.add(joiningMember);

          // Compute hash of the group key and send it along public Diffie-Hellman
          // shares of all group members to the joining member.
          BigInt groupKeyHash = await _computeGroupKeyHash();
          List<String> labels = List.empty(growable: true);
          List<String> values = List.empty(growable: true);
          _DHShare.forEach((label, value) {
            labels.add(label);
            values.add(value.toString());
          });

          SecureData msg = SecureData(
            GroupTag.join_rep.index, [groupKeyHash.toString(), labels, values]
          );

          _aodvManager.sendMessageTo(joiningMember, msg);
          break;

        case GroupTag.join_rep:
          // New member proceeds with the protocol from Step 3.
          if (payload.length == 3) {
            // Hash of group key
            _groupKey = SecretKey(_toBytes(BigInt.parse(payload[0] as String)));

            // Public Diffie-Hellman shares of group members
            List<String> labels = (payload[1] as List).cast<String>();
            List<String> values = (payload[2] as List).cast<String>();
            BigInt y = _computeDHShare();

            // Broadcast own Diffie-Hellman public share
            _DHShare.putIfAbsent(_ownLabel, () => y);
            for (int i = 0; i < labels.length; i++)
              _DHShare.putIfAbsent(labels[i], () => BigInt.parse(values[i]));

            // Solve systems of congruences
            for (final String label in _memberLabel) {
              if (label != _ownLabel) {
                BigInt mij = _computeMemberShare(label, _DHShare[label]!);
                BigInt crtij = _computeCRTShare(label, _DHShare[label]!, mij);

                SecureData msg = SecureData(
                  GroupTag.join_rep.index, [y.toString(), crtij.toString()]
                );

                _aodvManager.sendMessageTo(label, msg);
              }
            }
            // Compute group key
            _computeGroupKey(GroupTag.join, null);
          } else { // Old member updating the group key
            BigInt yj = BigInt.parse(payload[0] as String);
            BigInt mij = _computeMemberShare(senderLabel, yj);
            BigInt crtij = BigInt.parse(payload[1] as String);
            // Store the value send by the joining member
            _DHShare.putIfAbsent(senderLabel, () => yj);
            _memberShare.putIfAbsent(senderLabel, () => mij);
            _CRTShare.putIfAbsent(senderLabel, () => crtij);
            // Compute group key
            _computeGroupKey(GroupTag.join, senderLabel);
          }
          break;

        case GroupTag.leave:
          // Group owner redraw new key share and broadcast it to remaining group
          // member
          if (_groupOwner == _ownLabel) {
            _memberLabel.remove(senderLabel);
            _k = null;

            for (String label in _memberLabel) {
              if (label != _ownLabel) {
                BigInt yj = _DHShare[label]!;
                BigInt mij = _memberShare[label]!;
                // Redraw new key share
                BigInt crtij = _computeCRTShare(label, yj, mij);

                SecureData msg = SecureData(
                  GroupTag.leave.index, [senderLabel, crtij.toString()]
                );

                _aodvManager.sendMessageTo(label, msg);
              }
            }
            // Compute group key
            _computeGroupKey(GroupTag.leave);
          } else {
            // Remove value of leaving member
            String leavingMember = payload[0] as String;
            _memberLabel.remove(leavingMember);
            _DHShare.remove(leavingMember);
            _memberShare.remove(leavingMember);
            _CRTShare.remove(leavingMember);

            // Compute group key
            _CRTShare[_groupOwner!] = BigInt.parse(payload[1] as String);
            _computeGroupKey(GroupTag.leave);
          }
          break;

      default:
    }
  }
}
