import 'dart:async';
import 'dart:collection';

import 'package:adhoclibrary/src/appframework/config.dart';
import 'package:adhoclibrary/src/dataLink/service/adhoc_device.dart';
import 'package:adhoclibrary/src/datalink/service/discovery_event.dart';
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
import 'package:adhoclibrary/src/network/datalinkmanager/abstract_wrapper.dart';
import 'package:adhoclibrary/src/network/datalinkmanager/datalink_manager.dart';
import 'package:adhoclibrary/src/network/datalinkmanager/wrapper_event.dart';
import 'package:adhoclibrary/src/network/exceptions/adov_unknow_dest.dart';
import 'package:adhoclibrary/src/network/exceptions/aodv_unknown_type.dart';


class AodvManager {
  static const String TAG = '[AodvManager]';

  bool _verbose;
  AodvHelper aodvHelper;
  HashMap<String, int> mapDestSequenceNumber;
  StreamController<WrapperEvent> _eventCtrl;

  String _ownName;
  String _ownMac;
  String _ownAddress;
  int _ownSequenceNum;
  DataLinkManager _dataLink;
  MessageAdHoc _dataMessage;

  AodvManager(this._verbose, Config config) {
    this.aodvHelper = AodvHelper(_verbose);
    this._ownSequenceNum = Constants.FIRST_SEQUENCE_NUMBER;
    this.mapDestSequenceNumber = HashMap();
    this._ownAddress = config.label;
    this._dataLink = DataLinkManager(_verbose, config);
    this._eventCtrl = StreamController<WrapperEvent>();
    this._initialize();
    if (_verbose)
      this._initTimerDebugRIB();
  }

/*------------------------------Getters & Setters-----------------------------*/

  DataLinkManager get dataLinkManager => _dataLink;

  Stream<WrapperEvent> get eventStream async* {
    await for (WrapperEvent event in _eventCtrl.stream) {
      switch (event.type) {
        case AbstractWrapper.BROKEN_LINK:
          _brokenLinkDetected(event.payload);
          break;
        case AbstractWrapper.MESSAGE_EVENT:
          _processAodvMsgReceived(event.payload);
          break;
        case AbstractWrapper.DEVICE_INFO:
          _ownMac = event.payload;
          _ownName = event.extra;
          break;

        default:
          break;
      }

      yield event;
    }
  }

  Stream<DiscoveryEvent> get discoveryStream => _dataLink.discoveryStream;

/*------------------------------Public methods-------------------------------*/

  void sendMessageTo(Object pdu, String address) {
    Header header = Header(
      messageType: Constants.DATA, 
      name: _ownName,
      mac: _ownMac, 
      address: _ownAddress,
      deviceType: 0
    );

    MessageAdHoc msg = MessageAdHoc(header, Data(address, pdu));

    _send(msg, address);
  }

/*-----------------------------Private methods-------------------------------*/

  void _initialize() {
    _dataLink.eventStream.listen((event) {
      _eventCtrl.add(event);
    });
  }

  void _initTimerDebugRIB() {
    Timer.periodic(
      Duration(milliseconds: Constants.PERIOD), 
      (Timer timer) {
        Future.delayed(
          Duration(milliseconds: Constants.DELAY), 
          () => _displayRoutingTable()
        );
      }
    );
  }

  void _brokenLinkDetected(String remoteNode) {
    if (aodvHelper.sizeRoutingTable() > 0) {
      if (_verbose) log(TAG, 'Send RRER');
      sendRRER(remoteNode);
    }

    if (aodvHelper.containsDest(remoteNode)) {
      if (_verbose) log(TAG, 'Remove ' + remoteNode + ' from RIB');
      aodvHelper.removeEntry(remoteNode);
    }
  }

  void _saveDestSequenceNumber(String dest, int seqNum) {
    mapDestSequenceNumber.putIfAbsent(dest, () => seqNum);
  }

  void _displayRoutingTable() {
    bool display = false;
    StringBuffer buffer = new StringBuffer();

    if (aodvHelper.getEntrySet().length > 0) {
      display = true;

      buffer.write('--------Routing Table:--------\n');
      for (MapEntry<String, EntryRoutingTable> entry in aodvHelper.getEntrySet()) {
        buffer..write(entry.value.toString())..write("\n");
      }
    }

    if (mapDestSequenceNumber.length > 0) {
      display = true;
      buffer.write("--------SequenceNumber:--------\n");
      for (MapEntry<String, int> entry in mapDestSequenceNumber.entries) {
        buffer..write(entry.key)..write(" -> ")..write(entry.value.toString())..write("\n");
      }
    }

    if (display)
      log(TAG, buffer.toString());
  }

  void _getNextSequenceNumber() {
    if (_ownSequenceNum < Constants.MAX_VALID_SEQ_NUM) {
      ++_ownSequenceNum;
    } else {
      _ownSequenceNum = Constants.MIN_VALID_SEQ_NUM;
    }
  }

  void _sendDirect(MessageAdHoc message, String address) {
    _dataLink.sendMessage(message, address);
  }

  void _send(MessageAdHoc message, String address) {
    if (_dataLink.isDirectNeighbors(address)) {
      EntryRoutingTable destNext = aodvHelper.getNextfromDest(address);
      if (destNext != null && message.header.messageType == Constants.DATA) {
        destNext.updateDataPath(address);
      }

      _sendDirect(message, address);
    } else if (aodvHelper.containsDest(address)) {
      EntryRoutingTable destNext = aodvHelper.getNextfromDest(address);
      if (destNext == null) {
        if (_verbose) log(TAG, 'No destNext found in the routing Table for ' + address);
      } else {
        if (_verbose) log(TAG, 'Routing table contains ' + destNext.next);

        if (message.header.messageType == Constants.DATA)
          destNext.updateDataPath(address);

        _sendDirect(message, destNext.next);
      }
    } else if (message.header.messageType == Constants.RERR) {
      if (_verbose) log(TAG, 'RERR sent');
    } else {
      _dataMessage = message;
      _getNextSequenceNumber();
      startTimerRREQ(address, Constants.RREQ_RETRIES, Constants.NET_TRANVERSAL_TIME);
    }
  }

  void _processRREQ(MessageAdHoc message) {
    RREQ rreq = message.pdu as RREQ;
    int hop = rreq.hopCount;
    String originateAddr = message.header.label;
    if (_verbose) log(TAG, 'Received RREQ from ' + originateAddr);

    if (rreq.destAddress.compareTo(_ownAddress) == 0) {
      _saveDestSequenceNumber(rreq.originAddress, rreq.originSequenceNum);

      if (_verbose) log(TAG, _ownAddress + ' is the destination (stop RREQ broadcast)');

      EntryRoutingTable entry = aodvHelper.addEntryRoutingTable(
        rreq.originAddress, originateAddr, hop, rreq.originSequenceNum, Constants.NO_LIFE_TIME, null
      );

      if (entry != null) {
        if (rreq.destSequenceNum > _ownSequenceNum) {
          _getNextSequenceNumber();
        }

        RREP rrep = RREP(
          type: Constants.RREP, 
          hopCount: Constants.INIT_HOP_COUNT, 
          destAddress: rreq.originAddress, 
          sequenceNum: _ownSequenceNum, 
          originAddress: _ownAddress, 
          lifetime: Constants.LIFE_TIME
        );

        if (_verbose) log(TAG, 'Destination reachable via ' + entry.next);

        _send(
          MessageAdHoc(
            Header(
              messageType: Constants.RREP, 
              address: _ownAddress, 
              name: _ownName
            ),
            rrep
          ),
          entry.next
        );

        timerFlushReverseRoute(rreq.originAddress, rreq.originSequenceNum);
      }
    } else if (aodvHelper.containsDest(rreq.destAddress)) {
      _sendRREP_GRATUITOUS(message.header.label, rreq);
    } else {
      if (rreq.originAddress.compareTo(_ownAddress) == 0) {
        if (_verbose) log(TAG, 'Reject own RREQ ' + rreq.originAddress);
      } else if (aodvHelper.addBroadcastId(rreq.originAddress, rreq.rreqId)) {
        rreq.incrementHopCount();
        message.header = Header(
          messageType: Constants.RREQ, 
          address: _ownAddress,
          name: _ownName
        );
        message.pdu = rreq;

        _dataLink.broadcastExcept(message, originateAddr);

        aodvHelper.addEntryRoutingTable(rreq.originAddress, originateAddr, hop, rreq.originSequenceNum, Constants.NO_LIFE_TIME, null);

        timerFlushReverseRoute(rreq.originAddress, rreq.originSequenceNum);
      } else {
        if (_verbose) log(TAG, 'Already received this RREQ from ' + rreq.originAddress);
      }
    }
  }

  void _processRREP(MessageAdHoc message) {
    RREP rrep = message.pdu as RREP;
    int hopRcv = rrep.hopCount;
    String nextHop = message.header.label;

    if (_verbose) log(TAG, 'Received RREP from ' + nextHop);

    if (rrep.destAddress.compareTo(_ownAddress) == 0) {
      if (_verbose) log(TAG, _ownAddress + ' is the destination (stop RREP)');
        _saveDestSequenceNumber(rrep.originAddress, rrep.sequenceNum);

        aodvHelper.addEntryRoutingTable(rrep.originAddress, nextHop, hopRcv, rrep.sequenceNum, rrep.lifetime, null);

        Data data = _dataMessage.pdu as Data;
        _send(_dataMessage, data.destAddress);

        timerFlushForwardRoute(rrep.originAddress, rrep.sequenceNum, rrep.lifetime);
    } else {
      EntryRoutingTable destNext = aodvHelper.getNextfromDest(rrep.destAddress);
      if (destNext == null) {
        throw AodvUnknownDestException('No destNext found in the routing Table for ' + rrep.destAddress);
      } else {
        if (_verbose) log(TAG, 'Destination reachable via ' + destNext.next);

        rrep.incrementHopCount();
        _send(
          MessageAdHoc(
            Header(
              messageType: Constants.RREP, 
              address: _ownAddress,
              name: _ownName
            ), 
            rrep),
          destNext.next
        );

        aodvHelper.addEntryRoutingTable(rrep.originAddress, nextHop, hopRcv, rrep.sequenceNum, rrep.lifetime, _addPrecursors(destNext.next));

        timerFlushForwardRoute(rrep.originAddress, rrep.sequenceNum, rrep.lifetime);
      }
    }
  }

  void _processRREP_GRATUITOUS(MessageAdHoc message) {
    RREP rrep = message.pdu as RREP;
    int hopCount = rrep.incrementHopCount();

    if (rrep.destAddress.compareTo(_ownAddress) == 0) {
      if (_verbose) log(TAG, _ownAddress + ' is the destination (stop RREP)');

      aodvHelper.addEntryRoutingTable(rrep.originAddress, message.header.label, hopCount, rrep.sequenceNum, rrep.lifetime, null);

      timerFlushReverseRoute(rrep.originAddress, rrep.sequenceNum);
    } else {
      EntryRoutingTable destNext = aodvHelper.getNextfromDest(rrep.destAddress);
      if (destNext == null) {
        throw AodvUnknownDestException('No destNext found in the routing Table for ' + rrep.destAddress);
      } else {
        if (_verbose) log(TAG, 'Destination reachable via ' + destNext.next);
        
        aodvHelper.addEntryRoutingTable(rrep.originAddress, message.header.label, hopCount, rrep.sequenceNum, rrep.lifetime, _addPrecursors(destNext.next));

        timerFlushReverseRoute(rrep.originAddress, rrep.sequenceNum);

        message.header = Header(
          messageType: Constants.RREP_GRATUITOUS,
          address: _ownAddress,
          name: _ownName
        );

        _send(message, destNext.next);
      }
    }
  }

  void processRERR(MessageAdHoc message) {
    RERR rerr = message.pdu as RERR;
    String originateAddr = message.header.label;

    if (_verbose) log(TAG, 'Received RERR from ' + originateAddr + ' -> Node ' + rerr.unreachableDestAddress + ' is unreachable');

    if (rerr.unreachableDestAddress.compareTo(_ownAddress) == 0) {
      if (_verbose) log(TAG, 'RERR received on the destination (stop forward)');
    } else if (aodvHelper.containsDest(rerr.unreachableDestAddress)) {
      message.header = Header(
        messageType: Constants.RERR, 
        address: _ownAddress, 
        name: _ownName
      );
        
      List<String> precursors = aodvHelper.getPrecursorsFromDest(rerr.unreachableDestAddress);
      if (precursors != null) {
        for (String precursor in precursors) {
          if (_verbose) log(TAG, ' Precursor: ' + precursor);
            _send(message, precursor);
        }
      } else {
        if (_verbose) log(TAG, 'No precursors');
      }
      
      aodvHelper.removeEntry(rerr.unreachableDestAddress);
    } else {
      if (_verbose) log(TAG, 'Node does not contain dest: ' + rerr.unreachableDestAddress);
    }
  }

  void processData(MessageAdHoc message) {
    Data data = message.pdu as Data;

    if (_verbose) log(TAG, 'Data message received from: ' + message.header.label);

    if (data.destAddress.compareTo(_ownAddress) == 0) {
      if (_verbose) log(TAG, _ownAddress + ' is the destination (stop DATA message)');
    } else {
      EntryRoutingTable destNext = aodvHelper.getNextfromDest(data.destAddress);
      if (destNext == null) {
        throw AodvUnknownDestException('No destNext found in the routing Table for ' + data.destAddress);
      } else {
        if (_verbose) log(TAG, 'Destination reachable via ' + destNext.next);

        Header header = message.header;
        AdHocDevice adHocDevice = AdHocDevice(
          label: header.label, 
          mac: header.mac,
          name: header.name, 
          type: header.deviceType
        );

        destNext.updateDataPath(data.destAddress);

        _send(message, destNext.next);
      }
    }
  }

  void startTimerRREQ(final String destAddr, final int retry, final int time) {
    if (_verbose) log(TAG, 'No connection to ' + destAddr + ' -> send RREQ message');

    MessageAdHoc message = MessageAdHoc(
      Header(messageType: Constants.RREQ, 
        address: _ownAddress, 
        name: _ownName
      ),
      RREQ(
        type: Constants.RREQ, 
        hopCount: Constants.INIT_HOP_COUNT,
        rreqId: aodvHelper.getIncrementRreqId(),
        destSequenceNum: _getDestSequenceNumber(destAddr), 
        destAddress: destAddr, 
        originSequenceNum: _ownSequenceNum, 
        originAddress: _ownAddress
      )
    );
        
    _dataLink.broadcast(message);

  }

  void sendRRER(String brokenNodeAddress) {
    if (aodvHelper.containsNext(brokenNodeAddress)) {
      String dest = aodvHelper.getDestFromNext(brokenNodeAddress);
      if (dest.compareTo(_ownAddress) == 0) {
        if (_verbose) log(TAG, 'RERR received on the destination (stop forward)');
      } else {  
        RERR rrer = RERR(type: Constants.RERR, unreachableDestAddress: dest, unreachableDestSeqNum: _ownSequenceNum);
        List<String> precursors = aodvHelper.getPrecursorsFromDest(dest);
        if (precursors != null) {
          for (String precursor in precursors) {
            if (_verbose) log(TAG, 'send RERR to ' + precursor);
            _send(MessageAdHoc(Header(messageType: Constants.RERR, address: _ownAddress, name: _ownName), rrer), precursor);
          }
        }

        aodvHelper.removeEntry(dest);
      }
    }
  }

  void _sendRREP_GRATUITOUS(String senderAddr, RREQ rreq) {
    EntryRoutingTable entry = aodvHelper.getDestination(rreq.destAddress);

    entry.updatePrecursors(senderAddr);

    aodvHelper.addEntryRoutingTable(rreq.originAddress, senderAddr, rreq.hopCount, rreq.originSequenceNum, Constants.NO_LIFE_TIME, _addPrecursors(entry.next)
    );

    timerFlushReverseRoute(rreq.originAddress, rreq.originSequenceNum);

    RREP rrep = RREP(
      type: Constants.RREP_GRATUITOUS, 
      hopCount: rreq.hopCount, 
      destAddress: rreq.destAddress, 
      sequenceNum: _ownSequenceNum, 
      originAddress: rreq.originAddress, 
      lifetime: Constants.LIFE_TIME
    );

    _send(MessageAdHoc(Header(messageType: Constants.RREP_GRATUITOUS, address: _ownAddress, name: _ownName), rrep), entry.next);
    if (_verbose) log(TAG, 'Send Gratuitous RREP to ' + entry.next);

    rrep = RREP(
      type: Constants.RREP,
      hopCount: entry.hop + 1, 
      destAddress: rreq.originAddress, 
      sequenceNum: entry.destSeqNum, 
      originAddress:
      entry.destAddress,
      lifetime: Constants.LIFE_TIME
    );

    _send(MessageAdHoc(Header(messageType: Constants.RREP, address: _ownAddress, name: _ownName), rrep), rreq.originAddress);
    if (_verbose) log(TAG, 'Send RREP to ' + rreq.originAddress);
  }

  void timerFlushForwardRoute(final String destAddress, final int sequenceNum, final int lifeTime) {

  }

  void timerFlushReverseRoute(final String originAddress, final int sequenceNum) {

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
        throw AodvUnknownTypeException('Unknown AODV Type');
    }
  }

  List<String> _addPrecursors(String precursorName) {
    List<String> precursors = List();
    precursors.add(precursorName);
    return precursors;
  }

  int _getDestSequenceNumber(String dest) {
    if (mapDestSequenceNumber.containsKey(dest))
      return mapDestSequenceNumber[dest];
    return Constants.UNKNOWN_SEQUENCE_NUMBER;
  }
}
