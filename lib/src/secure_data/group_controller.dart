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
import 'package:ninja_prime/ninja_prime.dart';


class GroupController {
  AodvManager _aodvManager;
  DataLinkManager _datalinkManager;
  Stream<AdHocEvent> _eventStream;
  HashMap<String, BigInt> _membersShare;
  List<BigInt> _primes;
  int _expiryTime;

  int groupId;

  GroupController(this._aodvManager, this._datalinkManager, this._eventStream, Config config) {
    this._membersShare = HashMap();
    this._expiryTime = config.expiryTime;
    this._primes = _generatePrimeList();
    this.groupId = 1;
    this._initialize();
  }

  void createGroup(int groupId) {
    this.groupId = groupId;

    int P = 0, Q = 0;
    Data message = Data(GROUP_REQUEST, GroupData(_aodvManager.label, groupId, [P, Q /* Timestamp */]));
    _datalinkManager.broadcastObject(message);

    Timer(Duration(milliseconds: _expiryTime), _createGroupExpired);
  }

  void joinGroup() {
    
  }

  void leaveGroup() {
    
  }

  void _initialize() {
    _eventStream.listen((event) {
      if (event.type == DATA_RECEIVED) {
        _processData(event);
      }
    });
  }

  void _createGroupExpired() {
    _membersShare.putIfAbsent(_aodvManager.label, () => 0) /* own y_i */;

    List<String> membersLabel = List.empty(growable: true);
    for (final String label in _membersShare.keys)
      membersLabel.add(label);

    GroupData formation = GroupData(_aodvManager.label, groupId, [membersLabel, /* y_i */]);
    _datalinkManager.broadcastObject(Data(GROUP_FORMATION, formation));
  }

  void _processData(AdHocEvent event) {
    List payload = event.payload as List;
    AdHocDevice sender = payload[0] as AdHocDevice;
    Data pdu = Data.fromJson(payload[1] as Map);

    switch (pdu.type) {
      case GROUP_REQUEST:
        GroupData advertisement = pdu.payload as GroupData;
        if (advertisement.groupId != groupId) {
          _datalinkManager.broadcastObjectExcept(pdu, sender.label);
          break;
        }

        GroupData reply = GroupData(_aodvManager.label, groupId, [/* y_i */]);
        _aodvManager.sendMessageTo(Data(GROUP_REPLY, reply), sender.label);
        break;

      case GROUP_REPLY:
        GroupData reply = pdu.payload as GroupData;
        if (reply.groupId != groupId)
          break;

        _membersShare.putIfAbsent(reply.sender, () => BigInt.from(0)/* y_i */);
        break;

      case GROUP_FORMATION:
        GroupData reply = pdu.payload as GroupData;
        if (reply.groupId != groupId)
          break;

        for (String label in (reply.data as List)[0]) {
          _membersShare.putIfAbsent(label, () => BigInt.from(0));
          
        }

        break;

      case GROUP_JOIN:

        break; 

      case GROUP_LEAVE:

        break;

      default:
    }
  }

  List<BigInt> _generatePrimeList() {
    const N = 100;

    List<BigInt> result = List.filled(N, BigInt.zero);
    int n = (1.4 * N * log(N)) as int;

    List<bool> isPrimeArray = List.filled(n, true);
    isPrimeArray[0] = isPrimeArray[1] = false;

    for (int i = 2, primesLeft = N; i * i <= n && primesLeft > 0; i++) {
      if (isPrimeArray[i]) {
        result.add(BigInt.from(i));
        primesLeft--;

        for (int j = i; i * j <= n; j++) {
          isPrimeArray[i * j] = false;
        }
      }
    }

    print(result);

    return result;
  }

  BigInt _lowLevelPrimalityTest(int nBitsLength) {
    while (true) {
      BigInt primeCandidate = randomPrimeBigInt(nBitsLength);

      for (final BigInt divisor in _primes) {
        if ((primeCandidate % divisor) == BigInt.zero) {
          break;
        } else {
          return primeCandidate;
        }
      }
    }
  }
}
