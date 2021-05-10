import 'dart:async';
import 'dart:collection';

import 'package:adhoc_plugin/src/appframework/config.dart';
import 'package:adhoc_plugin/src/datalink/service/adhoc_device.dart';
import 'package:adhoc_plugin/src/datalink/service/adhoc_event.dart';
import 'package:adhoc_plugin/src/network/aodv/aodv_manager.dart';
import 'package:adhoc_plugin/src/network/datalinkmanager/constants.dart';
import 'package:adhoc_plugin/src/network/datalinkmanager/datalink_manager.dart';
import 'package:adhoc_plugin/src/secure_data/constants.dart';
import 'package:adhoc_plugin/src/secure_data/data.dart';
import 'package:adhoc_plugin/src/secure_data/group_data.dart';


class GroupController {
  AodvManager _aodvManager;
  DataLinkManager _datalinkManager;
  Stream<AdHocEvent> _eventStream;
  HashMap<String, int> _membersShare; // Transform into BigInt
  int _expiryTime;

  int groupId;

  GroupController(this._aodvManager, this._datalinkManager, this._eventStream, Config config) {
    this._membersShare = HashMap();
    this._expiryTime = config.expiryTime;
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
        List payload = event.payload as List;
        AdHocDevice sender = payload[0] as AdHocDevice;
        Data pdu = Data.fromJson(payload[1] as Map);
        _processData(sender, pdu);
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

  void _processData(AdHocDevice sender, Data pdu) {
    switch (pdu.type) {
      case GROUP_REQUEST:
        GroupData advertisement = pdu.payload as GroupData;
        if (advertisement.groupId != groupId)
          break;

        GroupData reply = GroupData(_aodvManager.label, groupId, [/* y_i */]);
        _aodvManager.sendMessageTo(Data(GROUP_REPLY, reply), sender.label);
        break;

      case GROUP_REPLY:
        GroupData reply = pdu.payload as GroupData;
        if (reply.groupId != groupId)
          break;

        _membersShare.putIfAbsent(reply.sender, () => 0 /* y_i */);
        break;

      case GROUP_FORMATION:
        GroupData reply = pdu.payload as GroupData;
        if (reply.groupId != groupId)
          break;

        for (String label in (reply.data as List)[0]) {
          _membersShare.putIfAbsent(label, () => 0);
          
        }

        break;

      case GROUP_JOIN:

        break; 

      case GROUP_LEAVE:

        break;

      default:
    }
  }
}
