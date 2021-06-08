import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:adhoc_plugin/src/appframework/config.dart';
import 'package:adhoc_plugin/src/datalink/service/adhoc_device.dart';
import 'package:adhoc_plugin/src/datalink/service/adhoc_event.dart';
import 'package:adhoc_plugin/src/network/aodv/aodv_manager.dart';
import 'package:adhoc_plugin/src/network/datalinkmanager/constants.dart';
import 'package:adhoc_plugin/src/network/datalinkmanager/datalink_manager.dart';
import 'package:adhoc_plugin/src/presentation/constants.dart';
import 'package:adhoc_plugin/src/presentation/crypto/crypto_engine.dart';
import 'package:adhoc_plugin/src/presentation/exceptions/group_not_formed.dart';
import 'package:adhoc_plugin/src/presentation/group/group_init.dart';
import 'package:adhoc_plugin/src/presentation/group/group_join.dart';
import 'package:adhoc_plugin/src/presentation/group/group_leave.dart';
import 'package:adhoc_plugin/src/presentation/group/group_list.dart';
import 'package:adhoc_plugin/src/presentation/group/group_value.dart';
import 'package:adhoc_plugin/src/presentation/secure_data.dart';
import 'package:cryptography/cryptography.dart';
import 'package:ninja_prime/ninja_prime.dart';

/// Class managing the creation and maintenance of a secure group
class GroupController {
  final AodvManager _aodvManager;
  final DataLinkManager _datalinkManager;
  final CryptoEngine _engine;
  final Stream<AdHocEvent> _eventStream;
  late String _ownLabel;
  late StreamController<AdHocEvent> _controller;

  late bool _open;
  late bool _timerExpired;
  late bool _isGroupFormed;
  late bool _isFormationGoingOn;
  late Set<String> _setFloodEvents;

  /// Order of the finite cyclic group
  BigInt? _p;
  /// Generator of the finite cyclic group of order [_p]
  BigInt? _g;
  /// Private Diffie-Hellman share
  BigInt? _x;
  /// Private key share
  BigInt? _k;
  /// Private share
  BigInt? _d;
  /// Secret group key
  SecretKey? _groupKey;
  /// Time allowed for joining the group creation process
  late int _expiryTime;
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

  /// Creates a [GroupController] object.
  /// 
  /// This object is configured according to [config], which contains specific 
  /// configurations.
  GroupController(
    this._engine, this._aodvManager, this._datalinkManager, this._eventStream, 
    Config config
  ) {
    _ownLabel = _aodvManager.label;
    _controller = StreamController<AdHocEvent>.broadcast();
    _open = config.public;
    _isGroupFormed = false;
    _setFloodEvents = <String>{};
    _k = null;
    _d = null;
    _expiryTime = config.expiryTime;
    _isFormationGoingOn = false;
    _timerExpired = false;
    _recovered = 0;
    _DHShare = HashMap();
    _memberShare = HashMap();
    _CRTShare = HashMap();
    _memberLabel = List.empty(growable: true);
    _initialize();
  }

/*------------------------------Getters & Setters-----------------------------*/

  /// Stream of ad hoc event notifications of lower layers.
  Stream<AdHocEvent> get eventStream => _controller.stream;

  /// Stance about joining group formation for any init request
  set public(bool state) => _open = state;

/*-------------------------------Public methods-------------------------------*/

  /// Initiates a secure group creation process
  /// 
  /// If [members] is given, then the group formation request is send to every
  /// member in the list.
  void createGroup([List<String>? members]) {
    if (_isFormationGoingOn || _isGroupFormed) {
      return;
    }

    _isFormationGoingOn = true;

    _groupOwner = _ownLabel;
    _memberLabel.add(_ownLabel);

    // Timestamp for flood control
    var timestamp = _ownLabel + DateTime.now().toIso8601String();
    var low = 32;
    var seed = max(low + low, Random(42).nextInt(192));

    // Choose Diffie-Hellman parameters
    _p = randomPrimeBigInt(seed);
    _g = randomPrimeBigInt(low);

    var info = GroupInit(timestamp, _p.toString(), _g.toString(), _ownLabel, false);
    var message = SecureData(GROUP_INIT, info.toJson());

    if (members == null) {
      // Broadcast formation group advertisement
      _datalinkManager.broadcastObject(message);
    } else {
      info.invitation = true;
      // Send to labels specified only
      for (final label in members) {
        _aodvManager.sendMessageTo(label, message);
      }
    }

    Timer(Duration(seconds: _expiryTime), _broadcastTimerExpired);
  }


  /// Joins an existing secure group
  /// 
  /// If [label] is given, then the join group request is sent to label
  void joinSecureGroup([String? label]) {
    // Send a group join request
    if (label == null) {
      var msg = SecureData(GROUP_JOIN, []);

      _datalinkManager.broadcastObject(msg);
    } else {
      var msg = SecureData(GROUP_JOIN_REQ, [_ownLabel]);

      _aodvManager.sendMessageTo(label, msg);
    }
  }


  /// Leaves an existing secure group
  void leaveSecureGroup() {
    if (!_isFormationGoingOn || !_isGroupFormed) {
      return;
    }

    _isGroupFormed = false;

    // Send a leave group notification
    var msg = SecureData(GROUP_LEAVE, GroupLeave(_ownLabel, ));
    _aodvManager.sendMessageTo(_groupOwner!, msg);

    // Reset cryptographic parameters
    _p = _g = _x = _k = BigInt.zero;
    _groupKey = null;
    _memberLabel.clear();
    _memberShare.clear();
    _DHShare.clear();
    _CRTShare.clear();
    _isFormationGoingOn = false;
  }


  /// Sends a encrypted message to the secure group.
  /// 
  /// The message payload is set to [data] and is encrypted using the group key.
  /// 
  /// Throws a [GroupNotFormedException] exception if the group is not formed
  /// or the device is not part of any secure group.
  void sendMessageToGroup(Object? data) async {
    if (!_isGroupFormed) {
      throw GroupNotFormedException();
    }

    var encrypted = await _engine.encrypt(
      Utf8Encoder().convert(JsonCodec().encode(data)), 
      sharedKey: _groupKey!,
    );

    // Send encrypted message to group member
    var _data = SecureData(GROUP_DATA, encrypted);
    for (final String? label in _memberLabel) {
      if (label != _ownLabel) {
        _aodvManager.sendMessageTo(label!, _data);
      }
    }
  }

/*------------------------------Private methods-------------------------------*/

  /// Initializes the listening process of lower layer streams.
  void _initialize() {
    _eventStream.listen((event) {
      if (event.type == DATA_RECEIVED) {
        var sender = (event.payload as List<dynamic>)[0] as AdHocDevice;
        var payload = SecureData.fromJson(
          (event.payload as List<dynamic>)[1] as Map<String, dynamic>
        );

        _processDataReceived(sender, payload);
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
  void _broadcastTimerExpired() {
    _timerExpired = true;

    var message = SecureData(GROUP_LIST, GroupList(_memberLabel));

    for (final label in _memberLabel) {
      if (label != _ownLabel) {
        _aodvManager.sendMessageTo(label, message);
      }
    }

    var y = _computeDHShare();
    _DHShare.putIfAbsent(_ownLabel, () => y);

    message = SecureData(GROUP_SHARE, GroupValue(y.toString()));

    for (final label in _memberLabel) {
      if (label != _ownLabel) {
        _aodvManager.sendMessageTo(label, message);
      }
    }
  }

  
  /// Computes the Diffie-Hellman secret share.
  /// 
  /// The Diffie-Hellman secret share is computed from [yj] sent by a remote
  /// node identified by [label].
  /// 
  /// Returns an integer value as [BigInt] representing the secret share.
  BigInt _computeMemberShare(String label, BigInt yj) {
    var mij = yj.modPow(_x!, _p!);
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
    BigInt pij, _min = _memberShare.values.first;

    // Choose p_ij such that gcd(p_ij , m_ij) = 1
    while (true) {
      pij = randomBigInt(_p!.bitLength);
      if (mij.gcd(pij) == BigInt.one) {
        break;
      }
    }

    if (_k == null) {
      // Choose random k_i such that k_i < min(m_ij) , for all j (1 < j < n)
      _memberShare.forEach((label, value) {
        if (value < _min) {
          _min = value;
        }
      });

      _min = _min < BigInt.one ? BigInt.one : _min;

      _k = randomBigInt(_min.bitLength, max: _min);
      _recovered += 1;

      if (_d == null) {
        // Choose randim d_i such that d_i != k_i
        _d = _k!;
        while (_k == _d) {
          _d = randomBigInt(_p!.bitLength);
        }
      }
    }

    // Solve the system of congruences (Chinese Remainder Theorem) using the 
    // Bézout's identity to obtain crt_ij
    var coefficients = _solveBezoutIdentity(mij, pij);
    var crtij = (_k! * coefficients[1] * pij) + (_d! * coefficients[0] * mij);
    if (crtij < BigInt.zero) {
      crtij % (mij * pij);
    }

    return crtij;
  }


  /// Solves the Bézout identity.
  /// 
  /// The system parameters is set to [a] and [b].
  /// 
  /// Returns a list of integer value as [BigInt] that represents the solution
  /// of the system.
  List<BigInt> _solveBezoutIdentity(BigInt a, BigInt b) {
    var R = a, _R = b, U = BigInt.one, _U = BigInt.zero;
    var V = BigInt.zero, _V = BigInt.one;

    while (_R != BigInt.zero) {
      var Q = R~/_R;
      var RS = R, US = U, VS = V;
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

    var byteData = ByteData((bigInt.bitLength~/BYTE_SIZE) + 1);
    var _bigInt = bigInt;

    for (var i = 1; i <= byteData.lengthInBytes; i++) {
      byteData.setUint8(
        byteData.lengthInBytes - i, _bigInt.toUnsigned(BYTE_SIZE).toInt()
      );

      _bigInt = _bigInt >> BYTE_SIZE;
    }

    return byteData.buffer.asUint8List();
  }

  
  /// Computes a hash of the group key.
  Future<BigInt> _computeGroupKeyHash() async {
    final hash = await Sha256().hash(await _groupKey!.extractBytes());
    return BigInt.from(hash.bytes.reduce((a, b) => a + b));
  }


  /// Computes the group key.
  /// 
  /// The way the group key is computed is defined by [type].
  void _computeGroupKey(int type, [String? label]) async {
    var groupKeySum = BigInt.zero;
    var groupKeyHash = BigInt.zero;

    switch (type) {
      case GROUP_INIT:
        groupKeySum += _k!;
        for (final label in _CRTShare.keys) {
          groupKeySum ^= (_CRTShare[label]! % _memberShare[label]!);
        }
        break;

      case GROUP_JOIN:
        groupKeyHash = await _computeGroupKeyHash();

        if (label == null) {
          groupKeySum = groupKeyHash ^ _k!;
        } else {
          groupKeySum = groupKeyHash ^ (_CRTShare[label]! % _memberShare[label]!);
        }
        break;

      case GROUP_LEAVE:
        if (_groupOwner == _ownLabel) {
          groupKeySum ^= _k!;
        } else {
          groupKeySum ^= (_CRTShare[_groupOwner]! % _memberShare[_groupOwner]!);
        }
        break;

      default:
    }

    var keyLengthRequired = 32;
    var keyBytes = _toBytes(groupKeySum);
    var length = keyBytes.length;
    if (length < keyLengthRequired) {
      keyBytes = Uint8List.fromList(keyBytes.toList() + List.filled(keyLengthRequired - length, 42));
    } else if (length > keyLengthRequired) {
      keyBytes = keyBytes.sublist(0, keyLengthRequired);
    }

    final algorithm = Chacha20(macAlgorithm: Hmac.sha256());
    _groupKey = await algorithm.newSecretKeyFromBytes(keyBytes);

    if (!_isGroupFormed) {
      _isGroupFormed = true;
      _controller.add(AdHocEvent(GROUP_STATUS, type));
    }

    _isFormationGoingOn = false;
  }


  /// Processes the data received.
  /// 
  /// The data is retrieved from the [event] payload.
  void _processDataReceived(AdHocDevice sender, SecureData secureData) async {
    var senderLabel = sender.label!;

    switch (secureData.type) {
      case GROUP_INIT:
        // Retrieve group advertisement data
        var data = GroupInit.fromJson(secureData.payload as Map<String, dynamic>);

        // Advertisement flood control
        if (!_setFloodEvents.contains(data.timestamp)) {
          _setFloodEvents.add(data.timestamp);
          // If private invitation, then do not broadcast
          if (!data.invitation) {
            _datalinkManager.broadcastObjectExcept(secureData, senderLabel);
          }
        }

        // Config specifies to reject all public advertisement
        if (!_open && !data.invitation) {
          return;
        }

        // Reject own advertisement
        if (_ownLabel == data.initiator) {
          return;
        } else {
          // Store group owner label
          _groupOwner = data.initiator;
        }

        // Store Diffie-Hellman parameters
        _p = BigInt.parse(data.modulo);
        _g = BigInt.parse(data.generator);
        // Reply to the group formation
        var msg = SecureData(GROUP_REPLY, null);
        _aodvManager.sendMessageTo(senderLabel, msg);
        break;


      case GROUP_REPLY:
        if (_timerExpired) {
          return;
        }

        if (!_memberLabel.contains(senderLabel)) {
          _memberLabel.add(senderLabel);
        }
        break;


      case GROUP_LIST:
        // Retrieve group list data
        var data = GroupList.fromJson(secureData.payload as Map<String, dynamic>);
        // Get all the label of the group member
        _memberLabel.addAll(data.labels);

        // Compute own public Diffie-Hellman share
        var y = _computeDHShare();
        _DHShare.putIfAbsent(_ownLabel, () => y);

        // Broadcast it to group member
        var msg = SecureData(GROUP_SHARE, GroupValue(y.toString()).toJson());
        for (final label in _memberLabel) {
          if (label != _ownLabel) {
            _aodvManager.sendMessageTo(label, msg.toJson());
          }
        }
        break;


      case GROUP_SHARE:
        // Retrieve group share data
        var data = GroupValue.fromJson(secureData.payload as Map<String, dynamic>);
        // Store the public Diffie-Hellman share of group memeber
        var yj = BigInt.parse(data.value);
        _DHShare.putIfAbsent(senderLabel, () => yj);

        // Once received all, solve the CRT system of congruence for each
        // group member
        if (_DHShare.length == _memberLabel.length) {
          for (var label in _memberLabel) {
            if (label == _ownLabel) {
              continue;
            }

            yj = _DHShare[label]!;

            var mij = _computeMemberShare(label, yj);
            var crtij = _computeCRTShare(label, yj, mij);
            var msg = SecureData(GROUP_KEY, GroupValue(crtij.toString()).toJson());

            _aodvManager.sendMessageTo(label, msg.toJson());
          }
        }
        break;


      case GROUP_KEY:
        // Retrieve group key share data
        var data = GroupValue.fromJson(secureData.payload as Map<String, dynamic>);
        var crtji = BigInt.parse(data.value);
        // Store the solution of the CRT system of congruence
        _CRTShare.putIfAbsent(senderLabel, () { _recovered += 1; return crtji; });

        // Compute the group key
        if (_recovered == _memberLabel.length) {
          _computeGroupKey(GROUP_INIT);
        }
        break;


      case GROUP_JOIN:
        // Send the group join request to the group owner
        var msg = SecureData(GROUP_JOIN_REQ, GroupValue(senderLabel).toJson());
        _aodvManager.sendMessageTo(_groupOwner!, msg);
        break;


      case GROUP_JOIN_REQ:
        // Retrieve joining member label data
        var data = GroupValue.fromJson(secureData.payload as Map<String, dynamic>);
        var joiningMember = data.value;
        if (_memberLabel.contains(joiningMember)) {
          break;
        } else {
          _memberLabel.add(joiningMember);
        }

        // Compute hash of the group key and send it along public Diffie-Hellman
        // shares of all group members to the joining member.
        var groupKeyHash = await _computeGroupKeyHash();
        var labels = List<String>.empty(growable: true);
        var values = List<String>.empty(growable: true);
        _DHShare.forEach((label, value) {
          labels.add(label);
          values.add(value.toString());
        });

        var response = GroupJoin(
          hash: groupKeyHash.toString(), labels: labels, values: values
        );

        var msg = SecureData(GROUP_JOIN_REP, response.toJson());

        _aodvManager.sendMessageTo(joiningMember, msg.toJson());
        break;


      case GROUP_JOIN_REP:
        // Retrieve joining member label data
        var data = GroupJoin.fromJson(secureData.payload as Map<String, dynamic>);

        // New member proceeds with the protocol from Step 3.
        if (data.hash != null) {
          // Hash of group key
          _groupKey = SecretKey(_toBytes(BigInt.parse(data.hash!)));

          // Public Diffie-Hellman shares of group members
          var labels = data.labels;
          var values = data.values;
          var y = _computeDHShare();

          // Broadcast own Diffie-Hellman public share
          _DHShare.putIfAbsent(_ownLabel, () => y);
          for (var i = 0; i < labels!.length; i++) {
            _DHShare.putIfAbsent(labels[i], () => BigInt.parse(values![i]));
          }

          // Solve systems of congruences
          for (final label in _memberLabel) {
            if (label != _ownLabel) {
              var mij = _computeMemberShare(label, _DHShare[label]!);
              var crtij = _computeCRTShare(label, _DHShare[label]!, mij);

              var response = GroupJoin(share: y.toString(), solution: crtij.toString());
              var msg = SecureData(GROUP_JOIN_REP, response.toJson());

              _aodvManager.sendMessageTo(label, msg);
            }
          }
          // Compute group key
          _computeGroupKey(GROUP_JOIN, null);
        } else { // Old member updating the group key
          var yj = BigInt.parse(data.share!);
          var mij = _computeMemberShare(senderLabel, yj);
          var crtij = BigInt.parse(data.solution!);

          // Store the value send by the joining member
          _DHShare.putIfAbsent(senderLabel, () => yj);
          _memberShare.putIfAbsent(senderLabel, () => mij);
          _CRTShare.putIfAbsent(senderLabel, () => crtij);

          // Compute group key
          _computeGroupKey(GROUP_JOIN, senderLabel);
        }
        break;


      case GROUP_LEAVE:
        // Retrieve joining member label data
        var data = GroupLeave.fromJson(secureData.payload as Map<String, dynamic>);

        // Group owner redraw new key share and broadcast it to remaining group member
        if (_groupOwner == _ownLabel) {
          _memberLabel.remove(senderLabel);
          _k = null;

          for (var label in _memberLabel) {
            if (label != _ownLabel) {
              var yj = _DHShare[label]!;
              var mij = _memberShare[label]!;
              // Redraw new key share
              var crtij = _computeCRTShare(label, yj, mij);

              var response = GroupLeave(data.leavingLabel, newSolution: crtij.toString());
              var msg = SecureData(GROUP_LEAVE, response.toJson());

              _aodvManager.sendMessageTo(label, msg);
            }
          }
          // Compute group key
          _computeGroupKey(GROUP_LEAVE);
        } else {
          // Remove value of leaving member
          var leavingMember = data.leavingLabel;
          _memberLabel.remove(leavingMember);
          _DHShare.remove(leavingMember);
          _memberShare.remove(leavingMember);
          _CRTShare.remove(leavingMember);

          // Compute group key
          _CRTShare[_groupOwner!] = BigInt.parse(data.newSolution!);
          _computeGroupKey(GROUP_LEAVE);
        }
        break;


      case GROUP_DATA:
        // Decrypt group data received
        var decrypted = await _engine.decrypt(secureData.payload as List<dynamic>, sharedKey: _groupKey!);
        var processed = JsonCodec().decode(Utf8Decoder().convert(decrypted));

        // Notify upper layers of group data received
        _controller.add(AdHocEvent(DATA_RECEIVED, [sender, processed]));
        break;

      default:
    }
  }
}
