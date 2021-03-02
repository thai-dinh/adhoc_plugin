import 'dart:async';
import 'dart:collection';

import 'package:adhoclibrary/adhoclibrary.dart' hide DataLinkManager, AodvHelper;
import 'package:adhoclibrary_example/network/aodv/aodv_helper.dart';
import 'package:adhoclibrary_example/network/datalinkmanager/datalink_manager.dart';
import 'package:adhoclibrary_example/network/aodv/constants.dart' as Constants;


class AodvManager {
  static const String TAG = '[AodvManager]';

  final bool _verbose;

  AodvHelper _aodvHelper;
  HashMap<String, int> _mapDestSequenceNumber;
  StreamController<AdHocEvent> _eventCtrl;

  String _ownName;
  String _ownMac;
  String _ownLabel;
  int _ownSequenceNum;
  DataLinkManager _dataLink;
  MessageAdHoc _dataMessage;

  StreamController<String> _logCtrl;

  AodvManager(this._verbose, Config config, int index, List<AdHocDevice> devices) {
    this._logCtrl = StreamController<String>();
    this._aodvHelper = AodvHelper(_logCtrl);
    this._ownSequenceNum = Constants.FIRST_SEQUENCE_NUMBER;
    this._mapDestSequenceNumber = HashMap();
    this._ownLabel = devices[index].label;
    this._dataLink = DataLinkManager(_verbose, config, index, devices);
    this._eventCtrl = StreamController<AdHocEvent>();
    this._initialize();
    if (_verbose)
      this._initTimerDebugRIB();
  }

/*------------------------------Getters & Setters-----------------------------*/

  DataLinkManager get dataLinkManager => _dataLink;

  Stream<String> get logs => _logCtrl.stream;

  Stream<AdHocEvent> get eventStream => _eventCtrl.stream;

/*------------------------------Public methods-------------------------------*/

  void sendMessageTo(Object pdu, String address) {
    Header header = Header(
      messageType: Constants.DATA,
      label: _ownLabel,
      name: _ownName,
      mac: _ownMac,
    );

    MessageAdHoc msg = MessageAdHoc(header, Data(address, pdu));

    _send(msg, address);
  }

/*-----------------------------Private methods-------------------------------*/

  void _initialize() {
    _dataLink.eventStream.listen((AdHocEvent event) {
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
          _eventCtrl.add(event);
          break;
      }
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

  void _displayRoutingTable() {
    bool display = false;
    StringBuffer buffer = new StringBuffer();

    if (_aodvHelper.getEntrySet().length > 0) {
      display = true;

      buffer.write('--------Routing Table:--------\n');
      for (MapEntry<String, EntryRoutingTable> entry in _aodvHelper.getEntrySet()) {
        buffer..write(entry.value.toString())..write('\n');
      }
    }

    if (_mapDestSequenceNumber.length > 0) {
      display = true;
      buffer.write('--------SequenceNumber:--------\n');
      for (MapEntry<String, int> entry in _mapDestSequenceNumber.entries) {
        buffer..write(entry.key)..write(' -> ')..write(entry.value.toString())..write('\n');
      }
    }

    if (display)
      print(buffer.toString());
  }

  void _brokenLinkDetected(String remoteNode) {
    if (_aodvHelper.sizeRoutingTable() > 0) {
      _logCtrl.add('Send RRER');
      _sendRRER(remoteNode);
    }

    if (_aodvHelper.containsDest(remoteNode)) {
      _logCtrl.add('Remove $remoteNode from RIB');
      _aodvHelper.removeEntry(remoteNode);
    }
  }

  void _send(MessageAdHoc message, String address) {
    if (_dataLink.isDirectNeighbors(address)) {
      EntryRoutingTable destNext = _aodvHelper.getNextfromDest(address);
      if (destNext != null && message.header.messageType == Constants.DATA)
        destNext.updateDataPath(address);
      _sendDirect(message, address);
    } else if (_aodvHelper.containsDest(address)) {
      EntryRoutingTable destNext = _aodvHelper.getNextfromDest(address);
      if (destNext == null) {
        _logCtrl.add('No destNext found in the routing Table for $address');
      } else {
        _logCtrl.add('Routing table contains ${destNext.next}');

        if (message.header.messageType == Constants.DATA)
          destNext.updateDataPath(address);

        _sendDirect(message, destNext.next);
      }
    } else if (message.header.messageType == Constants.RERR) {
      _logCtrl.add('RERR sent');
    } else {
      _dataMessage = message;
      _getNextSequenceNumber();
      _startTimerRREQ(address, Constants.RREQ_RETRIES, Constants.NET_TRANVERSAL_TIME);
    }
  }

  void _sendDirect(MessageAdHoc message, String address) {
    _dataLink.sendMessage(message, address);
  }

  void _startTimerRREQ(String destAddr, int retry, int time) {
    _logCtrl.add('No connection to $destAddr -> send RREQ message');

    MessageAdHoc message = MessageAdHoc(
      Header(messageType: Constants.RREQ, 
        label: _ownLabel,
        name: _ownName,
        mac: _ownMac
      ),
      RREQ(
        type: Constants.RREQ,
        hopCount: Constants.INIT_HOP_COUNT,
        rreqId: _aodvHelper.getIncrementRreqId(),
        destSequenceNum: _getDestSequenceNumber(destAddr), 
        destAddress: destAddr,
        originSequenceNum: _ownSequenceNum,
        originAddress: _ownLabel
      )
    );

    _dataLink.broadcast(message);

    Timer(Duration(milliseconds: time), () {
      EntryRoutingTable entry = _aodvHelper.getNextfromDest(destAddr);
      if (entry == null) {
        if (retry == 0) {
          _eventCtrl.add(AdHocEvent(
            AbstractWrapper.INTERNAL_EXCEPTION,
            AodvMessageException(
              'Unable to establish a communication with: $destAddr'
            )
          ));
        } else {
          _startTimerRREQ(destAddr, retry - 1, time * 2);
        }
      }
    });
  }

  List<String> _addPrecursors(String precursorName) {
    return List<String>.empty(growable: true)..add(precursorName);
  }

  int _getDestSequenceNumber(String dest) {
    if (_mapDestSequenceNumber.containsKey(dest))
      return _mapDestSequenceNumber[dest];
    return Constants.UNKNOWN_SEQUENCE_NUMBER;
  }

  void _getNextSequenceNumber() {
    if (_ownSequenceNum < Constants.MAX_VALID_SEQ_NUM) {
      ++_ownSequenceNum;
    } else {
      _ownSequenceNum = Constants.MIN_VALID_SEQ_NUM;
    }
  }

  void _saveDestSequenceNumber(String dest, int seqNum) {
    _mapDestSequenceNumber.putIfAbsent(dest, () => seqNum);
  }

  void _processRREQ(MessageAdHoc message) {
    RREQ rreq = RREQ.fromJson(message.pdu as Map);
    int hop = rreq.hopCount;
    String originateAddr = message.header.label;
    _logCtrl.add('Received RREQ from $originateAddr');

    if (rreq.destAddress.compareTo(_ownLabel) == 0) {
      _saveDestSequenceNumber(rreq.originAddress, rreq.originSequenceNum);

      _logCtrl.add('$_ownLabel is the destination (stop RREQ broadcast)');

      EntryRoutingTable entry = _aodvHelper.addEntryRoutingTable(
        rreq.originAddress, originateAddr, hop, rreq.originSequenceNum, Constants.NO_LIFE_TIME, null
      );

      if (entry != null) {
        if (rreq.destSequenceNum > _ownSequenceNum)
          _getNextSequenceNumber();

        RREP rrep = RREP(
          type: Constants.RREP, 
          hopCount: Constants.INIT_HOP_COUNT, 
          destAddress: rreq.originAddress, 
          sequenceNum: _ownSequenceNum, 
          originAddress: _ownLabel, 
          lifetime: Constants.LIFE_TIME
        );

        _logCtrl.add('Destination reachable via ${entry.next}');

        _send(
          MessageAdHoc(
            Header(
              messageType: Constants.RREP, 
              label: _ownLabel, 
              name: _ownName,
              mac: _ownMac
            ),
            rrep
          ),
          entry.next
        );

        // _timerFlushReverseRoute(rreq.originAddress, rreq.originSequenceNum);
      }
    } else if (_aodvHelper.containsDest(rreq.destAddress)) {
      _sendRREP_GRATUITOUS(message.header.label, rreq);
    } else {
      if (rreq.originAddress.compareTo(_ownLabel) == 0) {
        _logCtrl.add('Reject own RREQ ${rreq.originAddress}');
      } else if (_aodvHelper.addBroadcastId(rreq.originAddress, rreq.rreqId)) {
        rreq.incrementHopCount();
        message.header = Header(
          messageType: Constants.RREQ, 
          label: _ownLabel,
          name: _ownName,
          mac: _ownMac
        );
        message.pdu = rreq;

        _dataLink.broadcastExcept(message, originateAddr);

        _aodvHelper.addEntryRoutingTable(rreq.originAddress, originateAddr, hop, rreq.originSequenceNum, Constants.NO_LIFE_TIME, null);

        // _timerFlushReverseRoute(rreq.originAddress, rreq.originSequenceNum);
      } else {
        _logCtrl.add('Already received this RREQ from ${rreq.originAddress}');
      }
    }
  }

  void _processRREP(MessageAdHoc message) {
    RREP rrep = RREP.fromJson(message.pdu as Map);
    int hopRcv = rrep.hopCount;
    String nextHop = message.header.label;

    _logCtrl.add('Received RREP from $nextHop');

    if (rrep.destAddress.compareTo(_ownLabel) == 0) {
      _logCtrl.add('$_ownLabel is the destination (stop RREP)');
        _saveDestSequenceNumber(rrep.originAddress, rrep.sequenceNum);

        _aodvHelper.addEntryRoutingTable(rrep.originAddress, nextHop, hopRcv, rrep.sequenceNum, rrep.lifetime, null);

        Data data = _dataMessage.pdu as Data;
        _send(_dataMessage, data.destAddress);

        // _timerFlushForwardRoute(rrep.originAddress, rrep.sequenceNum, rrep.lifetime);
    } else {
      EntryRoutingTable destNext = _aodvHelper.getNextfromDest(rrep.destAddress);
      if (destNext == null) {
        throw AodvUnknownDestException('No destNext found in the routing Table for ${rrep.destAddress}');
      } else {
        _logCtrl.add('Destination reachable via ${destNext.next}');

        rrep.incrementHopCount();
        _send(
          MessageAdHoc(
            Header(
              messageType: Constants.RREP, 
              label: _ownLabel,
              name: _ownName,
              mac: _ownMac
            ), 
            rrep),
          destNext.next
        );

        _aodvHelper.addEntryRoutingTable(rrep.originAddress, nextHop, hopRcv, rrep.sequenceNum, rrep.lifetime, _addPrecursors(destNext.next));

        // _timerFlushForwardRoute(rrep.originAddress, rrep.sequenceNum, rrep.lifetime);
      }
    }
  }

  void _processRREP_GRATUITOUS(MessageAdHoc message) {
    RREP rrep = RREP.fromJson(message.pdu as Map);
    int hopCount = rrep.incrementHopCount();

    if (rrep.destAddress.compareTo(_ownLabel) == 0) {
      _logCtrl.add('$_ownLabel is the destination (stop RREP)');

      _aodvHelper.addEntryRoutingTable(rrep.originAddress, message.header.label, hopCount, rrep.sequenceNum, rrep.lifetime, null);

      _timerFlushReverseRoute(rrep.originAddress, rrep.sequenceNum);
    } else {
      EntryRoutingTable destNext = _aodvHelper.getNextfromDest(rrep.destAddress);
      if (destNext == null) {
        throw AodvUnknownDestException('No destNext found in the routing Table for ${rrep.destAddress}');
      } else {
        _logCtrl.add('Destination reachable via ${destNext.next}');
        
        _aodvHelper.addEntryRoutingTable(rrep.originAddress, message.header.label, hopCount, rrep.sequenceNum, rrep.lifetime, _addPrecursors(destNext.next));

        _timerFlushReverseRoute(rrep.originAddress, rrep.sequenceNum);

        message.header = Header(
          messageType: Constants.RREP_GRATUITOUS,
          label: _ownLabel,
          name: _ownName,
          mac: _ownMac
        );

        _send(message, destNext.next);
      }
    }
  }

  void _processRERR(MessageAdHoc message) {
    RERR rerr = RERR.fromJson(message.pdu as Map);
    String originateAddr = message.header.label;

    _logCtrl.add('Received RERR from $originateAddr -> Node ${rerr.unreachableDestAddress} is unreachable');

    if (rerr.unreachableDestAddress.compareTo(_ownLabel) == 0) {
      _logCtrl.add('RERR received on the destination (stop forward)');
    } else if (_aodvHelper.containsDest(rerr.unreachableDestAddress)) {
      message.header = Header(
        messageType: Constants.RERR, 
        label: _ownLabel, 
        name: _ownName,
        mac: _ownMac
      );
        
      List<String> precursors = _aodvHelper.getPrecursorsFromDest(rerr.unreachableDestAddress);
      if (precursors != null) {
        for (String precursor in precursors) {
          _logCtrl.add(' Precursor: $precursor');
            _send(message, precursor);
        }
      } else {
        _logCtrl.add('No precursors');
      }
      
      _aodvHelper.removeEntry(rerr.unreachableDestAddress);
    } else {
      _logCtrl.add('Node does not contain dest: ${rerr.unreachableDestAddress}');
    }
  }

  void _processData(MessageAdHoc message) {
    Data data = Data.fromJson(message.pdu as Map);

    _logCtrl.add('Data message received from: ${message.header.label}');

    if (data.destAddress.compareTo(_ownLabel) == 0) {
      _logCtrl.add(_ownLabel + ' is the destination (stop DATA message)');

      Header header = message.header;
      AdHocDevice adHocDevice = AdHocDevice(
        label: header.label,
        name: header.name,
        mac: header.mac,
        type: header.deviceType
      );

      _eventCtrl.add(AdHocEvent(AbstractWrapper.DATA_RECEIVED, adHocDevice, extra: data.payload));
    } else {
      EntryRoutingTable destNext = _aodvHelper.getNextfromDest(data.destAddress);
      if (destNext == null) {
        throw AodvUnknownDestException('No destNext found in the routing Table for ${data.destAddress}');
      } else {
        _logCtrl.add('Destination reachable via ${destNext.next}');

        Header header = message.header;
        AdHocDevice adHocDevice = AdHocDevice(
          label: header.label,
          name: header.name,
          mac: header.mac,
          type: header.deviceType
        );

        _eventCtrl.add(AdHocEvent(AbstractWrapper.FORWARD_DATA, adHocDevice, extra: data.payload));

        destNext.updateDataPath(data.destAddress);

        _send(message, destNext.next);
      }
    }
  }

  void _sendRRER(String brokenNodeAddress) {
    if (_aodvHelper.containsNext(brokenNodeAddress)) {
      String dest = _aodvHelper.getDestFromNext(brokenNodeAddress);
      if (dest.compareTo(_ownLabel) == 0) {
        _logCtrl.add('RERR received on the destination (stop forward)');
      } else {  
        RERR rrer = RERR(type: Constants.RERR, unreachableDestAddress: dest, unreachableDestSeqNum: _ownSequenceNum);
        List<String> precursors = _aodvHelper.getPrecursorsFromDest(dest);
        if (precursors != null) {
          for (String precursor in precursors) {
            _logCtrl.add('send RERR to $precursor');
            _send(
              MessageAdHoc(
                Header(
                  messageType: Constants.RERR, 
                  label: _ownLabel, 
                  name: _ownName,
                  mac: _ownMac
                ),
                rrer
              ),
              precursor
            );
          }
        }

        _aodvHelper.removeEntry(dest);
      }
    }
  }

  void _sendRREP_GRATUITOUS(String senderAddr, RREQ rreq) {
    EntryRoutingTable entry = _aodvHelper.getDestination(rreq.destAddress);

    entry.updatePrecursors(senderAddr);

    _aodvHelper.addEntryRoutingTable(
      rreq.originAddress, senderAddr, rreq.hopCount, rreq.originSequenceNum, 
      Constants.NO_LIFE_TIME, _addPrecursors(entry.next)
    );

    _timerFlushReverseRoute(rreq.originAddress, rreq.originSequenceNum);

    RREP rrep = RREP(
      type: Constants.RREP_GRATUITOUS, 
      hopCount: rreq.hopCount, 
      destAddress: rreq.destAddress, 
      sequenceNum: _ownSequenceNum, 
      originAddress: rreq.originAddress, 
      lifetime: Constants.LIFE_TIME
    );

    _send(
      MessageAdHoc(
        Header(
          messageType: Constants.RREP_GRATUITOUS,
          label: _ownLabel,
          name: _ownName,
          mac: _ownMac
        ), 
        rrep
      ), 
      entry.next
    );

    _logCtrl.add('Send Gratuitous RREP to ${entry.next}');

    rrep = RREP(
      type: Constants.RREP,
      hopCount: entry.hop + 1, 
      destAddress: rreq.originAddress, 
      sequenceNum: entry.destSeqNum, 
      originAddress:
      entry.destAddress,
      lifetime: Constants.LIFE_TIME
    );

    _send(
      MessageAdHoc(
        Header(
          messageType: Constants.RREP,
          label: _ownLabel,
          name: _ownName,
          mac: _ownMac
        ),
        rrep),
      rreq.originAddress
    );

    _logCtrl.add('Send RREP to ${rreq.originAddress}');
  }

  void _timerFlushForwardRoute(String destAddress, int sequenceNum, int lifeTime) {
    Timer(Duration(milliseconds: lifeTime),
      () {
        _logCtrl.add('Add timer for $destAddress - seq: $sequenceNum - lifeTime: $lifeTime');

        int lastChanged = _aodvHelper.getDataPathFromAddress(destAddress);
        int difference = (DateTime.now().millisecond - lastChanged);

        if (lastChanged == 0) {
          _aodvHelper.removeEntry(destAddress);
          _logCtrl.add('No Data on $destAddress');
        } else if (difference < lifeTime) {
          _timerFlushForwardRoute(destAddress, sequenceNum, lifeTime);
        } else {
          _aodvHelper.removeEntry(destAddress);
          _logCtrl.add('No Data on $destAddress since $difference');
        }
      }
    );
  }

  void _timerFlushReverseRoute(String originAddress, int sequenceNum) {
    Timer(Duration(milliseconds: Constants.EXPIRED_TABLE),
      () {
        _logCtrl.add('Add timer for $originAddress - seq: $sequenceNum');

        int lastChanged = _aodvHelper.getDataPathFromAddress(originAddress);
        int difference = (DateTime.now().millisecond - lastChanged);
        if (lastChanged == 0) {
          _aodvHelper.removeEntry(originAddress);
          _logCtrl.add('No Data on $originAddress');
        } else if (difference < Constants.EXPIRED_TIME) {
          _timerFlushReverseRoute(originAddress, sequenceNum);
        } else {
          _aodvHelper.removeEntry(originAddress);
          _logCtrl.add('No Data on $originAddress since $difference');
        }
      }
    );
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
        _processRERR(message);
        _getNextSequenceNumber();
        break;
      case Constants.DATA:
        _processData(message);
        break;
      default:
        throw AodvUnknownTypeException('Unknown AODV Type');
    }
  }
}
