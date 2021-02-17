import 'dart:async';
import 'dart:collection';

import 'package:adhoclibrary/src/datalink/service/adhoc_device.dart';
import 'package:adhoclibrary/src/datalink/utils/msg_adhoc.dart';
import 'package:adhoclibrary/src/datalink/utils/msg_header.dart';
import 'package:adhoclibrary/src/datalink/utils/utils.dart';
import 'package:adhoclibrary/src/network/aodv/aodv_helper.dart';
import 'package:adhoclibrary/src/network/aodv/constants.dart' as Constants;
import 'package:adhoclibrary/src/network/aodv/data.dart';
import 'package:adhoclibrary/src/network/aodv/entry_routing_table.dart';
import 'package:adhoclibrary/src/network/aodv/rerr.dart';
import 'package:adhoclibrary/src/network/aodv/rrep.dart';
import 'package:adhoclibrary/src/network/aodv/rreq.dart';
import 'package:adhoclibrary/src/network/datalinkmanager/datalink_manager.dart';
import 'package:adhoclibrary/src/network/exceptions/adov_unknow_dest.dart';
import 'package:adhoclibrary/src/network/exceptions/aodv_unknown_type.dart';


class AodvManager {
  static const String TAG = "[AodvManager]";

  bool _verbose;
  AodvHelper aodvHelper;
  HashMap<String, int> mapDestSequenceNumber;

  String ownName;
  String ownMac;
  String ownAddress;
  int ownSequenceNum;
  DataLinkManager dataLink;
  MessageAdHoc dataMessage;

  AodvManager(this._verbose) {
    this.aodvHelper = AodvHelper(_verbose);
    this.ownSequenceNum = Constants.FIRST_SEQUENCE_NUMBER;
    this.mapDestSequenceNumber = HashMap();
    if (_verbose)
      this._initTimerDebugRIB();
  }

/*------------------------------Public methods-------------------------------*/

  void sendMessageTo(Object pdu, String address) {
    Header header = Header(
      messageType: Constants.DATA, 
      name: ownName,
      mac: ownMac, 
      address: ownAddress,
      deviceType: 0
    );

    MessageAdHoc msg = MessageAdHoc(header, Data(destIpAddress: address, payload: pdu));

    _send(msg, address);
  }

/*-----------------------------Private methods-------------------------------*/

  void _initTimerDebugRIB() {
    Timer.periodic(
      Duration(milliseconds: Constants.PERIOD), 
      (Timer timer) {
        Future.delayed(
          Duration(milliseconds: Constants.DELAY), 
          () => _updateRoutingTable()
        );
      }
    );
  }

  void saveDestSequenceNumber(String dest, int seqNum) {
    mapDestSequenceNumber.putIfAbsent(dest, () => seqNum);
  }

  void _updateRoutingTable() {
    bool display = false;
  }

  void _getNextSequenceNumber() {
    if (ownSequenceNum < Constants.MAX_VALID_SEQ_NUM) {
      ++ownSequenceNum;
    } else {
      ownSequenceNum = Constants.MIN_VALID_SEQ_NUM;
    }
  }

  void _brokenLinkDetected(String remoteNode) {
    if (aodvHelper.sizeRoutingTable() > 0) {
      if (_verbose) log(TAG, "Send RRER");
      sendRRER(remoteNode);
    }

    if (aodvHelper.containsDest(remoteNode)) {
      if (_verbose) log(TAG, "Remove " + remoteNode + " from RIB");
      aodvHelper.removeEntry(remoteNode);
    }
  }

  void _sendDirect(MessageAdHoc message, String address) {
    dataLink.sendMessage(message, address);
  }

  void _send(MessageAdHoc message, String address) {
    if (dataLink.isDirectNeighbors(address)) {
      EntryRoutingTable destNext = aodvHelper.getNextfromDest(address);
      if (destNext != null && message.header.messageType == Constants.DATA) {
        destNext.updateDataPath(address);
      }

      _sendDirect(message, address);
    } else if (aodvHelper.containsDest(address)) {
      EntryRoutingTable destNext = aodvHelper.getNextfromDest(address);
      if (destNext == null) {
        if (_verbose) log(TAG, "No destNext found in the routing Table for " + address);
      } else {
        if (_verbose) log(TAG, "Routing table contains " + destNext.next);

        if (message.header.messageType == Constants.DATA)
          destNext.updateDataPath(address);

        _sendDirect(message, destNext.next);
      }
    } else if (message.header.messageType == Constants.RERR) {
      if (_verbose) log(TAG, "RERR sent");
    } else {
      dataMessage = message;
      _getNextSequenceNumber();
      startTimerRREQ(address, Constants.RREQ_RETRIES, Constants.NET_TRANVERSAL_TIME);
    }
  }

  void _processRREQ(MessageAdHoc message) {
    RREQ rreq = message.pdu as RREQ;
    int hop = rreq.hopCount;
    String originateAddr = message.header.label;
    if (_verbose) log(TAG, "Received RREQ from " + originateAddr);

    if (rreq.destIpAddress.compareTo(ownAddress) == 0) {
      saveDestSequenceNumber(rreq.originIpAddress, rreq.originSequenceNum);

      if (_verbose) log(TAG, ownAddress + " is the destination (stop RREQ broadcast)");

      EntryRoutingTable entry = aodvHelper.addEntryRoutingTable(
        rreq.originIpAddress, originateAddr, hop, rreq.originSequenceNum, Constants.NO_LIFE_TIME, null
      );

      if (entry != null) {
        if (rreq.destSequenceNum > ownSequenceNum) {
          _getNextSequenceNumber();
        }

        RREP rrep = RREP(
          type: Constants.RREP, 
          hopCount: Constants.INIT_HOP_COUNT, 
          destIpAddress: rreq.originIpAddress, 
          sequenceNum: ownSequenceNum, 
          originIpAddress: ownAddress, 
          lifetime: Constants.LIFE_TIME
        );

        if (_verbose) log(TAG, "Destination reachable via " + entry.next);

        _send(
          MessageAdHoc(
            Header(
              messageType: Constants.RREP, 
              address: ownAddress, 
              name: ownName
            ),
            rrep
          ),
          entry.next
        );

        timerFlushReverseRoute(rreq.originIpAddress, rreq.originSequenceNum);
      }
    } else if (aodvHelper.containsDest(rreq.destIpAddress)) {
      _sendRREP_GRAT(message.header.label, rreq);
    } else {
      if (rreq.originIpAddress.compareTo(ownAddress) == 0) {
        if (_verbose) log(TAG, "Reject own RREQ " + rreq.originIpAddress);
      } else if (aodvHelper.addBroadcastId(rreq.originIpAddress, rreq.rreqId)) {
        rreq.incrementHopCount();
        message.header = Header(
          messageType: Constants.RREQ, 
          address: ownAddress,
          name: ownName
        );
        message.pdu = rreq;

        dataLink.broadcastExcept(message, originateAddr);

        aodvHelper.addEntryRoutingTable(rreq.originIpAddress, originateAddr, hop, rreq.originSequenceNum, Constants.NO_LIFE_TIME, null);

        timerFlushReverseRoute(rreq.originIpAddress, rreq.originSequenceNum);
      } else {
        if (_verbose) log(TAG, "Already received this RREQ from " + rreq.originIpAddress);
      }
    }
  }

  void _processRREP(MessageAdHoc message) {
    RREP rrep = message.pdu as RREP;
    int hopRcv = rrep.hopCount;
    String nextHop = message.header.label;

    if (_verbose) log(TAG, "Received RREP from " + nextHop);

    if (rrep.destIpAddress.compareTo(ownAddress) == 0) {
      if (_verbose) log(TAG, ownAddress + " is the destination (stop RREP)");
        saveDestSequenceNumber(rrep.originIpAddress, rrep.sequenceNum);

        aodvHelper.addEntryRoutingTable(rrep.originIpAddress, nextHop, hopRcv, rrep.sequenceNum, rrep.lifetime, null);

        Data data = dataMessage.pdu as Data;
        _send(dataMessage, data.destIpAddress);

        timerFlushForwardRoute(rrep.originIpAddress, rrep.sequenceNum, rrep.lifetime);
    } else {
      EntryRoutingTable destNext = aodvHelper.getNextfromDest(rrep.destIpAddress);
      if (destNext == null) {
        throw AodvUnknownDestException("No destNext found in the routing Table for " + rrep.destIpAddress);
      } else {
        if (_verbose) log(TAG, "Destination reachable via " + destNext.next);

        rrep.incrementHopCount();
        _send(
          MessageAdHoc(
            Header(
              messageType: Constants.RREP, 
              address: ownAddress,
              name: ownName
            ), 
            rrep),
          destNext.next
        );

        aodvHelper.addEntryRoutingTable(rrep.originIpAddress, nextHop, hopRcv, rrep.sequenceNum, rrep.lifetime, addPrecursors(destNext.next));

        timerFlushForwardRoute(rrep.originIpAddress, rrep.sequenceNum, rrep.lifetime);
      }
    }
  }

  void _processRREP_GRATUITOUS(MessageAdHoc message) {
    RREP rrep = message.pdu as RREP;
    int hopCount = rrep.incrementHopCount();

    if (rrep.destIpAddress.compareTo(ownAddress) == 0) {
      if (_verbose) log(TAG, ownAddress + " is the destination (stop RREP)");

      aodvHelper.addEntryRoutingTable(rrep.originIpAddress, message.header.label, hopCount, rrep.sequenceNum, rrep.lifetime, null);

      timerFlushReverseRoute(rrep.originIpAddress, rrep.sequenceNum);
    } else {
      EntryRoutingTable destNext = aodvHelper.getNextfromDest(rrep.destIpAddress);
      if (destNext == null) {
        throw AodvUnknownDestException("No destNext found in the routing Table for " + rrep.destIpAddress);
      } else {
        if (_verbose) log(TAG, "Destination reachable via " + destNext.next);
        
        aodvHelper.addEntryRoutingTable(rrep.originIpAddress, message.header.label, hopCount, rrep.sequenceNum, rrep.lifetime, addPrecursors(destNext.next));

        timerFlushReverseRoute(rrep.originIpAddress, rrep.sequenceNum);

        message.header = Header(
          messageType: Constants.RREP_GRATUITOUS,
          address: ownAddress,
          name: ownName
        );

        _send(message, destNext.next);
      }
    }
  }

  void processRERR(MessageAdHoc message) {
    RERR rerr = message.pdu as RERR;
    String originateAddr = message.header.label;

    if (_verbose) log(TAG, "Received RERR from " + originateAddr + " -> Node " + rerr.unreachableDestIpAddress + " is unreachable");

    if (rerr.unreachableDestIpAddress.compareTo(ownAddress) == 0) {
      if (_verbose) log(TAG, "RERR received on the destination (stop forward)");
    } else if (aodvHelper.containsDest(rerr.unreachableDestIpAddress)) {
      message.header = Header(
        messageType: Constants.RERR, 
        address: ownAddress, 
        name: ownName
      );
        
      List<String> precursors = aodvHelper.getPrecursorsFromDest(rerr.unreachableDestIpAddress);
      if (precursors != null) {
        for (String precursor in precursors) {
          if (_verbose) log(TAG, " Precursor: " + precursor);
            _send(message, precursor);
        }
      } else {
        if (_verbose) log(TAG, "No precursors");
      }
      
      aodvHelper.removeEntry(rerr.unreachableDestIpAddress);
    } else {
      if (_verbose) log(TAG, "Node doesn't contain dest: " + rerr.unreachableDestIpAddress);
    }
  }

  void processData(MessageAdHoc message) {
    Data data = message.pdu as Data;

    if (_verbose) log(TAG, "Data message received from: " + message.header.label);

    if (data.destIpAddress.compareTo(ownAddress) == 0) {
      if (_verbose) log(TAG, ownAddress + " is the destination (stop DATA message)");
    } else {
      EntryRoutingTable destNext = aodvHelper.getNextfromDest(data.destIpAddress);
      if (destNext == null) {
        throw AodvUnknownDestException("No destNext found in the routing Table for " + data.destIpAddress);
      } else {
        if (_verbose) log(TAG, "Destination reachable via " + destNext.next);

        Header header = message.header;
        AdHocDevice adHocDevice = AdHocDevice(
          label: header.label, 
          mac: header.mac,
          name: header.name, 
          type: header.deviceType
        );

        destNext.updateDataPath(data.destIpAddress);

        _send(message, destNext.next);
      }
    }
  }

  void startTimerRREQ(final String destAddr, final int retry, final int time) {
    if (_verbose) log(TAG, "No connection to " + destAddr + " -> send RREQ message");

    MessageAdHoc message = MessageAdHoc(
      Header(messageType: Constants.RREQ, 
        address: ownAddress, 
        name: ownName
      ),
      RREQ(
        type: Constants.RREQ, 
        hopCount: Constants.INIT_HOP_COUNT,
        rreqId: aodvHelper.getIncrementRreqId(),
        destSequenceNum: getDestSequenceNumber(destAddr), 
        destIpAddress: destAddr, 
        originSequenceNum: ownSequenceNum, 
        originIpAddress: ownAddress
      )
    );
        
    dataLink.broadcast(message);

  }

  void sendRRER(String brokenNodeAddress) {
    if (aodvHelper.containsNext(brokenNodeAddress)) {
      String dest = aodvHelper.getDestFromNext(brokenNodeAddress);
      if (dest.compareTo(ownAddress) == 0) {
        if (_verbose) log(TAG, "RERR received on the destination (stop forward)");
      } else {  
        RERR rrer = RERR(type: Constants.RERR, unreachableDestIpAddress: dest, unreachableDestSeqNum: ownSequenceNum);
        List<String> precursors = aodvHelper.getPrecursorsFromDest(dest);
        if (precursors != null) {
          for (String precursor in precursors) {
            if (_verbose) log(TAG, "send RERR to " + precursor);
            _send(MessageAdHoc(Header(messageType: Constants.RERR, address: ownAddress, name: ownName), rrer), precursor);
          }
        }

        aodvHelper.removeEntry(dest);
      }
    }
  }

  void _sendRREP_GRAT(String senderAddr, RREQ rreq) {
    EntryRoutingTable entry = aodvHelper.getDestination(rreq.destIpAddress);

    entry.updatePrecursors(senderAddr);

    aodvHelper.addEntryRoutingTable(rreq.originIpAddress, senderAddr, rreq.hopCount, rreq.originSequenceNum, Constants.NO_LIFE_TIME, addPrecursors(entry.next)
    );

    timerFlushReverseRoute(rreq.originIpAddress, rreq.originSequenceNum);

    RREP rrep = RREP(
      type: Constants.RREP_GRATUITOUS, 
      hopCount: rreq.hopCount, 
      destIpAddress: rreq.destIpAddress, 
      sequenceNum: ownSequenceNum, 
      originIpAddress: rreq.originIpAddress, 
      lifetime: Constants.LIFE_TIME
    );

    _send(MessageAdHoc(Header(messageType: Constants.RREP_GRATUITOUS, address: ownAddress, name: ownName), rrep), entry.next);
    if (_verbose) log(TAG, "Send Gratuitous RREP to " + entry.next);

    rrep = RREP(
      type: Constants.RREP,
      hopCount: entry.hop + 1, 
      destIpAddress: rreq.originIpAddress, 
      sequenceNum: entry.destSeqNum, 
      originIpAddress:
      entry.destIpAddress,
      lifetime: Constants.LIFE_TIME
    );

    _send(MessageAdHoc(Header(messageType: Constants.RREP, address: ownAddress, name: ownName), rrep), rreq.originIpAddress);
    if (_verbose) log(TAG, "Send RREP to " + rreq.originIpAddress);
  }

  void timerFlushForwardRoute(final String destIpAddress, final int sequenceNum, final int lifeTime) {

  }

  void timerFlushReverseRoute(final String originIpAddress, final int sequenceNum) {

  }

  void _processAodvMsgReceived(MessageAdHoc message) {
    switch (message.header.messageType) {
      case Constants.RREQ:
        _processRREQ(message);
        _getNextSequenceNumber();
        break;
      case Constants.RREP:
        _processRREP(message);
        _getNextSequenceNumber();
        break;
      case Constants.RREP_GRATUITOUS:
        _processRREP_GRATUITOUS(message);
        _getNextSequenceNumber();
        break;
      case Constants.RERR:
        processRERR(message);
        _getNextSequenceNumber();
        break;
      case Constants.DATA:
        processData(message);
        break;
      default:
        throw AodvUnknownTypeException("Unknown AODV Type");
    }
  }

  List<String> addPrecursors(String precursorName) {
    List<String> precursors = List();
    precursors.add(precursorName);
    return precursors;
  }

  int getDestSequenceNumber(String dest) {
    if (mapDestSequenceNumber.containsKey(dest)) {
      return mapDestSequenceNumber[dest];
    }

    return Constants.UNKNOWN_SEQUENCE_NUMBER;
  }
}
