import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'constants.dart';
import 'secure_data.dart';
import '../appframework/config.dart';
import '../datalink/service/adhoc_device.dart';
import '../datalink/service/adhoc_event.dart';
import '../network/aodv/aodv_manager.dart';
import '../network/datalinkmanager/constants.dart';
import '../network/datalinkmanager/datalink_manager.dart';

import 'package:cryptography/cryptography.dart';
import 'package:ninja_prime/ninja_prime.dart';


/// Class managing the creation and maintenance of a secure group
class SecureGroupController {
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
  /// Secret group key
  SecretKey? _groupKey;
  /// Map containing the Diffie-Hellman share of each member
  late HashMap<String?, BigInt?> _DHShare;
  /// Map containing the member share of each member
  late HashMap<String?, BigInt?> _memberShare;
  /// Map containing the Chinese Remainder Theorem solution of each member
  late HashMap<String?, BigInt?> _CRTShare;
  /// List containing the group member label
  late List<String?> _memberLabel;

  /// Creates a [SecureGroupController] object.
  /// 
  /// 
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

  /// Returns a [Stream] of [AdHocEvent] events of lower layers.
  Stream<AdHocEvent> get eventStream => _eventCtrl.stream;

/*-------------------------------Public methods-------------------------------*/

  /// Initiates a secure group creation process
  void createSecureGroup() {
    _p = randomPrimeBigInt(512);
    _g = randomPrimeBigInt(256);

    SecureData message = SecureData(
      GROUP_REQUEST, [_p.toString(), _g.toString()]
    );

    _datalinkManager.broadcastObject(message);
    _memberLabel.add(_ownLabel);

    Timer(Duration(seconds: _expiryTime!), _createSecureGroupExpired);
  }


  /// Joins an existing secure group
  void joinSecureGroup() {
    SecureData message = SecureData(GROUP_JOIN_REQ, []);
    _datalinkManager.broadcastObject(message);
  }


  /// Leaves an existing secure group
  void leaveSecureGroup() {
    SecureData message = SecureData(GROUP_LEAVE_REQ, _memberLabel.first);
    for (final String? label in _memberLabel) {
      if (label! != _ownLabel)
        _aodvManager.sendMessageTo(label, message);
    }

    _p = _g = _x = _k = _groupKeySum = BigInt.zero;
    _groupKey = null;
    _memberLabel.clear();
    _memberShare.clear();
    _DHShare.clear();
    _CRTShare.clear();
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


  ///
  BigInt _computeDHShare() {
    // Step 1.
    // Select the Diffie-Hellman private share x_i and compute public share y_i
    _x = randomBigInt(_p!.bitLength, max: _p);
    return _g!.modPow(_x!, _p!);
  }

  
  ///
  void _createSecureGroupExpired() {
    // Step 2.
    // Broadcast y_i to group members
    _DHShare.putIfAbsent(_ownLabel, () => _computeDHShare());
    SecureData message = SecureData(
      GROUP_FORMATION_REQ, 
      [LEADER, _memberLabel, _DHShare[_ownLabel]!.toString()]
    );

    for (final String? label in _memberLabel)
      if (label != _ownLabel)
        _aodvManager.sendMessageTo(label!, message);
  }

  
  ///
  BigInt _computeMemberShare(String? label, BigInt? yj) {
    // Step 3.
    // Compute the Diffie-Hellman key shared of peers
    BigInt mij = yj!.modPow(_x!, _p!);
    mij = mij > (_p!~/BigInt.two) ? mij : _p! - mij;
    _memberShare.putIfAbsent(label, () => mij);
    return mij;
  }

  
  ///
  BigInt _computeCRTShare(String? label, BigInt? yj, BigInt? mij) {
    BigInt pij, di, _min = _memberShare.values.first!;

    // Step 4.
    // Choose p_ij such that gcd(p_ij , m_ij) = 1
    while (true) {
      pij = randomBigInt(_p!.bitLength);
      if (mij!.gcd(pij) == BigInt.one)
        break;
    }

    // Step 5.
    // Choose random k_i such that k_i < min(m_ij) , for all j (1 < j < n)
    _memberShare.forEach((label, value) {
      if (value! < _min)
        _min = value;
    });
    _min = _min < BigInt.one ? BigInt.one : _min;
  
    _k = randomBigInt(_min.bitLength, max: _min);

    // Choose randim d_i such that d_i != k_i
    di = _k!;
    while (_k == di)
      di = randomBigInt(_p!.bitLength);

    // Solve the system of congruences (Chinese Remainder Theorem) using the 
    // existence construction (Bézout's identity) to obtain crt_ij
    List<BigInt?> coefficients = _solveBezoutIdentity(mij, pij);
    BigInt crtij = 
      (_k! * coefficients[1]! * pij) + (di * coefficients[0]! * mij);
    while (crtij < BigInt.zero)
      crtij += (mij * pij);

    return crtij;
  }

  
  ///
  List<BigInt> _solveBezoutIdentity(BigInt? a, BigInt? b) {
    BigInt R = a!, _R = b!, U = BigInt.one, _U = BigInt.zero;
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

  
  ///
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

  
  ///
  void _computeGroupKey(int type, [BigInt? kj]) async {
    // Step 6.
    // Compute the group key
    _groupKeySum = _k!;
    switch (type) {
      case FORMATION:
        for (final String? label in _CRTShare.keys)
          _groupKeySum = _groupKeySum! ^ (_CRTShare[label]! % _memberShare[label]!);
        break;

      case JOIN:
        // final Sha256 algorithm = Sha256();
        // final Hash hash = await algorithm.hash([_groupKeySum!]);
        // _groupKeySum = _groupKeySum! ^ hash.bytes.reduce((a, b) => a + b);
        break;

      case LEAVE:
        _groupKeySum = _groupKeySum! ^ kj!;
        break;

      default:
    }

    _groupKey = SecretKey(_toBytes(_groupKeySum!));
  }


  ///
  void _processDataReceived(AdHocEvent event) async {
    AdHocDevice sender = (event.payload as List<dynamic>)[0] as AdHocDevice;
    String senderLabel = sender.label!;
    SecureData pdu = SecureData.fromJson(
      (event.payload as List<dynamic>)[1] as Map<String, dynamic>
    );

    switch (pdu.type) {
      case GROUP_REQUEST:
        _datalinkManager.broadcastObjectExcept(pdu, senderLabel);

        List<dynamic> data = pdu.payload as List<dynamic>;
        _p = BigInt.parse(data[0] as String);
        _g = BigInt.parse(data[1] as String);

        SecureData reply = SecureData(GROUP_REPLY, []);
        _aodvManager.sendMessageTo(senderLabel, reply);
        break;

      case GROUP_REPLY:
        _memberLabel.add(senderLabel);
        break;

      case GROUP_FORMATION_REQ:
        List<dynamic> data = pdu.payload as List<dynamic>;
        BigInt yj, mij, crtij;

        if (data[0] == LEADER) {
          /* Step 1: Compute own Diffie-Hellman share y_i */
          _DHShare.putIfAbsent(_ownLabel, () => _computeDHShare());

          // Store leader Diffie-Hellman share y_j
          yj = BigInt.parse(data[2] as String);
          _DHShare.putIfAbsent(senderLabel, () => yj);
          // Get the list of group member label
          _memberLabel.addAll((data[1] as List<dynamic>).cast<String>());

          /* Step 2: Broadcast y_i to group members */
          for (final String? label in _memberLabel) {
            if (label != _ownLabel) {
              SecureData reply = SecureData(
                GROUP_FORMATION_REQ, [MEMBER, _DHShare[_ownLabel].toString()]
              );

              _aodvManager.sendMessageTo(label!, reply);
            }
          }
        } else {
          // Recover y_j
          yj = BigInt.parse(data[1] as String);
        }

        // Store y_j
        _DHShare.putIfAbsent(senderLabel, () => yj);

        /* Step 3, 4 & 5 */
        // Compute y_j, m_ij, crt_ij of member
        mij = _computeMemberShare(senderLabel, yj);
        crtij = _computeCRTShare(senderLabel, yj, mij);

        // Compute crt_ij of group member
        SecureData reply = SecureData(GROUP_FORMATION_REP, crtij.toString());
        _aodvManager.sendMessageTo(sender.label!, reply);
        break;

      case GROUP_FORMATION_REP:
        // Store crt_ji received from group memeber
        _CRTShare.putIfAbsent(senderLabel, () => BigInt.parse(pdu.payload as String));
        // Increment the count of key shared received from peers
        _recovered = _recovered! + 1;
        if (_recovered == _CRTShare.length) 
          _computeGroupKey(FORMATION);
        break;

      case GROUP_JOIN_REQ:
        _memberLabel.add(senderLabel);
        Sha256 algorithm = Sha256();
        Hash hash = await algorithm.hash(_toBytes(_groupKeySum!));
        SecureData message = SecureData(
          GROUP_JOIN_REP, [REQUEST, _memberLabel, hash.bytes.reduce((a, b) => a + b), _DHShare]
        );

        _aodvManager.sendMessageTo(senderLabel, message);
        break;

      case GROUP_JOIN_REP:
        List<dynamic> data = pdu.payload as List<dynamic>;

        if (data[0] == REQUEST) {
          List<String?> memberLabel = (data[1] as List<dynamic>).cast<String?>();
          BigInt groupKeyHash = BigInt.parse(data[2] as String);
          Map<String, BigInt> DHShare = 
            (data[3] as Map<dynamic, dynamic>).cast<String, BigInt>();

          _memberLabel.addAll(memberLabel);
          _groupKeySum = groupKeyHash;
          DHShare.forEach((key, value) => _DHShare.putIfAbsent(key, () => value));

          BigInt yi = _computeDHShare();
          _DHShare.putIfAbsent(_ownLabel, () => yi);
          for (final String? label in _memberLabel) {
            if (label != _ownLabel) {
              SecureData message = SecureData(GROUP_JOIN_REP, [REPLY, yi.toString()]);
              _aodvManager.sendMessageTo(label!, message);

              BigInt mij = _computeMemberShare(label, _DHShare[label]!);
              BigInt crtij = _computeCRTShare(label, _DHShare[label], mij);
              SecureData reply = SecureData(
                GROUP_FORMATION_REP, [MEMBER, crtij.toString(), true]
              );

              _aodvManager.sendMessageTo(label, reply);
            }
          }
        } else {
          BigInt yj = BigInt.parse(data[1] as String);
          BigInt mij = _computeMemberShare(senderLabel, yj);
          _memberShare.putIfAbsent(senderLabel, () => mij);
          _computeGroupKey(JOIN);
        }
        break;

      case GROUP_LEAVE_REQ:
        _memberLabel.remove(senderLabel);
        _memberShare.remove(senderLabel);
        _DHShare.remove(senderLabel);
        _CRTShare.remove(senderLabel);

        if (pdu.payload as String == _ownLabel) {
          for (final String? label in _memberLabel) {
            BigInt crtij = _computeCRTShare(label, _DHShare[label], _memberShare[label]);
            SecureData reply = SecureData(GROUP_LEAVE_REP, crtij.toString());

            _aodvManager.sendMessageTo(label!, reply);
          }

          _computeGroupKey(LEAVE);
        }
        break;

      case GROUP_LEAVE_REP:
        _CRTShare.update(senderLabel, (value) => BigInt.parse(pdu.payload as String));
        _computeGroupKey(LEAVE);
        break;

      case GROUP_MESSAGE:
        List<dynamic> data = pdu.payload as List<dynamic>;

        // Set up the algorithm environment
        final AesCbc algorithm = AesCbc.with128bits(
          macAlgorithm: Hmac.sha256()
        );

        // Decrypt received data from group member
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

        // Reconstruct original data from bytes (Uint8List)
        dynamic _data = JsonCodec().decode(Utf8Decoder().convert(decrypted));
        // Notify upper layer (application layer) of data received
        _eventCtrl.add(AdHocEvent(DATA_RECEIVED, [sender, _data]));
        break;

      default:
    }
  }
}
