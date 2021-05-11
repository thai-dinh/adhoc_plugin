import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:adhoc_plugin/src/appframework/config.dart';
import 'package:adhoc_plugin/src/datalink/service/adhoc_device.dart';
import 'package:adhoc_plugin/src/datalink/service/adhoc_event.dart';
import 'package:adhoc_plugin/src/network/aodv/aodv_manager.dart';
import 'package:adhoc_plugin/src/network/datalinkmanager/constants.dart';
import 'package:adhoc_plugin/src/network/datalinkmanager/datalink_manager.dart';
import 'package:adhoc_plugin/src/secure_data/constants.dart';
import 'package:adhoc_plugin/src/secure_data/data.dart';
import 'package:adhoc_plugin/src/secure_data/group_data.dart';
import 'package:cryptography/cryptography.dart';
// import 'package:ninja_prime/ninja_prime.dart';


class GroupController {
  AodvManager? _aodvManager;
  DataLinkManager? _datalinkManager;
  Stream<AdHocEvent> _eventStream;
  late HashMap<String?, int> _membersShare;
  late HashMap<String?, int> _keyShare;
  SecretKey? _groupKey;
  int? _expiryTime;

  int? _GK;
  int? _counter;
  late int _secret;
  int? _mij;
  late int P;
  late int G;

  int? groupId;

  GroupController(this._aodvManager, this._datalinkManager, this._eventStream, Config config) {
    this._membersShare = HashMap();
    this._keyShare = HashMap();
    this._expiryTime = config.expiryTime;
    this._counter = 0;
    this.groupId = 1;
    this._initialize();
  }

/*-------------------------------Public methods-------------------------------*/

  void createGroup(int groupId) { // Step 1.
    this.groupId = groupId;

    List<int> primes = _generatePrimes();
    Data message = Data(
      GROUP_REQUEST, 
      GroupData(
        _aodvManager!.label, groupId, 
        [P = primes[0], G = primes[1]]
      ),
    );

    _datalinkManager!.broadcastObject(message);

    Timer(Duration(milliseconds: _expiryTime!), _createGroupExpired);
  }

  void joinGroup(int groupId) {
    
  }

  void leaveGroup() {
    
  }

/*------------------------------Private methods-------------------------------*/

  void _initialize() {
    _eventStream.listen((event) {
      if (event.type == DATA_RECEIVED) {
        _processData(event);
      }
    });
  }

  List<int> _generatePrimes() {
    List<int> primes = List.empty(growable: true);

    int P = Random().nextInt(2048);
    int Q = Random().nextInt(1024);

    return primes..add(P)..add(Q);
  }

  int _computeShare() {
    _secret = Random().nextInt(512);
    return pow(G, _secret).toInt() % P;
  }

  void _createGroupExpired() {
    _membersShare.putIfAbsent(_aodvManager!.label, () => _computeShare());

    List<String?> membersLabel = List.empty(growable: true);
    for (final String? label in _membersShare.keys)
      membersLabel.add(label);

    GroupData formation = GroupData(_aodvManager!.label, groupId, [LEADER, membersLabel, _membersShare[_aodvManager!.label]]);
    _datalinkManager!.broadcastObject(Data(GROUP_FORMATION_REQ, formation));
  }

  void _computeGroupKey() {
    for (final int share in _membersShare.values)
      _GK = _GK! ^ share;
    _groupKey = SecretKey(List<int?>.filled(1, _GK) as List<int>);
  }

  void _computeKeyShare(String? label, int yj) {
    int? pij, ki, di;
    int _min = 2147483647;

    /* Step 3 */
    _mij = pow(yj, _secret) % P as int?;
    _mij = _mij! > P/2 ? _mij : P - _mij!;

    /* Step 4 */
    bool found = false;
    while (!found) {
      if (_mij!.gcd(pij = Random().nextInt(2048)) == 1) {
        found = true;
      }
    }

    /* Step 5 */
    for (int value in _membersShare.values)
      _min = min(_min, value);

    ki = Random().nextInt(_min);
    di = ki;

    while (ki == di)
      di = Random().nextInt(2147483647);

    List<int?> coefficients = _solveBezoutIdentity(_mij, pij);
    int solution = (ki * coefficients[1]! * pij!) + (di! * coefficients[0]! * _mij!);
    while (solution < 0)
      solution += (_mij! * pij); // CRTij

    GroupData reply = GroupData(_aodvManager!.label, groupId, solution);
    _aodvManager!.sendMessageTo(Data(GROUP_FORMATION_REP, reply), label);
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

  void _processData(AdHocEvent event) {
    List payload = event.payload as List;
    AdHocDevice sender = payload[0] as AdHocDevice;
    Data pdu = Data.fromJson((payload[1] as Map) as Map<String, dynamic>);

    if (event.type >= GROUP_REQUEST) {
      GroupData data = pdu.payload as GroupData;
      if (data.groupId != groupId) {
        _datalinkManager!.broadcastObjectExcept(pdu, sender.label);
        return;
      }
    }

    switch (pdu.type) {
      case GROUP_REQUEST:
        GroupData advertisement = GroupData.fromJson(pdu.payload as Map<String, dynamic>);
        List<dynamic> data = advertisement.data as List;

        P = data[0] as int;
        G = data[1] as int;

        GroupData reply = GroupData(sender.label, groupId, _aodvManager!.label);
        _aodvManager!.sendMessageTo(Data(GROUP_REPLY, reply), sender.label);
        break;

      case GROUP_REPLY:
        GroupData reply = pdu.payload as GroupData;
        _membersShare.putIfAbsent(reply.data as String?, () => 0);
        break;

      case GROUP_FORMATION_REQ:
        GroupData reply = pdu.payload as GroupData;
        if ((reply.data as List)[0] == LEADER) {
          _membersShare.putIfAbsent(reply.leader, () => (reply.data as List)[2]);
          for (String label in (reply.data as List)[1])
            _membersShare.putIfAbsent(label, () => 0);

          _membersShare.putIfAbsent(_aodvManager!.label, () => _computeShare());
          GroupData formation = GroupData(_aodvManager!.label, groupId, [MEMBER, _membersShare[_aodvManager!.label]]);
          _datalinkManager!.broadcastObject(Data(GROUP_FORMATION_REQ, formation));
        } else {
          _membersShare.update(sender.label, (value) => value = (reply.data as List)[1]);
          _computeKeyShare(sender.label, _membersShare[sender.label]!);
        }
        break;

      case GROUP_FORMATION_REP:
        GroupData? reply = pdu.payload as GroupData?;
        _keyShare.update(sender.label, (value) => value = ((reply!.data as int) % _mij!));
        _counter = _counter! + 1;

        if (_counter == _membersShare.length)
          _computeGroupKey();
        break;

      case GROUP_JOIN:

        break;

      case GROUP_LEAVE:

        break;

      default:
    }
  }
}
