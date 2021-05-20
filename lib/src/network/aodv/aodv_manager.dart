import 'dart:async';
import 'dart:collection';

import 'package:adhoc_plugin/src/appframework/config.dart';
import 'package:adhoc_plugin/src/datalink/service/adhoc_device.dart';
import 'package:adhoc_plugin/src/datalink/service/adhoc_event.dart';
import 'package:adhoc_plugin/src/datalink/utils/msg_adhoc.dart';
import 'package:adhoc_plugin/src/datalink/utils/msg_header.dart';
import 'package:adhoc_plugin/src/datalink/utils/utils.dart';
import 'package:adhoc_plugin/src/network/aodv/aodv_helper.dart';
import 'package:adhoc_plugin/src/network/aodv/constants.dart' as AodvConstants;
import 'package:adhoc_plugin/src/network/aodv/data.dart';
import 'package:adhoc_plugin/src/network/aodv/entry_routing_table.dart';
import 'package:adhoc_plugin/src/network/aodv/rerr.dart';
import 'package:adhoc_plugin/src/network/aodv/rrep.dart';
import 'package:adhoc_plugin/src/network/aodv/rreq.dart';
import 'package:adhoc_plugin/src/network/datalinkmanager/constants.dart' as DatalinkConstants;
import 'package:adhoc_plugin/src/network/datalinkmanager/datalink_manager.dart';
import 'package:adhoc_plugin/src/network/exceptions/aodv_message.dart';
import 'package:adhoc_plugin/src/network/exceptions/aodv_unknown_dest.dart';
import 'package:adhoc_plugin/src/network/exceptions/aodv_unknown_type.dart';


/// Class representing the core of the AODV protocol. It manages all the 
/// messages received and to send.
class AodvManager {
  static const String TAG = '[AodvManager]';

  final bool _verbose;

  MessageAdHoc? _dataMessage;

  late String _ownMac;
  late String _ownName;
  late String _ownLabel;
  late int _ownSequenceNum;
  late AodvHelper _aodvHelper;
  late DataLinkManager _datalinkManager;
  late HashMap<String?, int?> _mapDestSeqNum;
  late StreamController<AdHocEvent> _controller;

  /// Creates a [AodvManager] object.
  /// 
  /// The debug/verbose mode is set if [_verbose] is true.
  /// 
  /// This object is configured with regards to [config], which contains
  /// specific configurations.
  AodvManager(this._verbose, Config config) {
    this._ownMac = '';
    this._ownName = 'i';
    this._ownLabel = config.label;
    this._ownSequenceNum = AodvConstants.FIRST_SEQUENCE_NUMBER;
    this._aodvHelper = AodvHelper(_verbose);
    this._datalinkManager = DataLinkManager(_verbose, config);
    this._mapDestSeqNum = HashMap();
    this._controller = StreamController<AdHocEvent>.broadcast();
    this._initialize();
    if (_verbose) // Periodical display of the routing table
      this._initTimerDebugRIB();
  }

/*------------------------------Getters & Setters-----------------------------*/

  /// Returns the label as [String] of the current node.
  String get label => _ownLabel;

  /// Returns the [DataLinkManager] object used by this AODV manager.
  DataLinkManager get dataLinkManager => _datalinkManager;

  /// Returns a [Stream] of [AdHocEvent] event of lower layers.
  Stream<AdHocEvent> get eventStream => _controller.stream;

/*------------------------------Public methods-------------------------------*/

  /// Sends a message with payload as [pdu] to a remote [address].
  void sendMessageTo(String address, Object pdu) {
    // Create the header of the message
    Header header = Header(
      messageType: AodvConstants.DATA,
      label: _ownLabel,
      name: _ownName,
      mac: _ownMac,
    );

    _send(MessageAdHoc(header, Data(address, pdu)), address);
  }

/*-----------------------------Private methods-------------------------------*/

  /// Initializes the listening process of lower layer streams.
  void _initialize() {
    _datalinkManager.eventStream.listen((AdHocEvent event) {
      switch (event.type) {
        case DatalinkConstants.BROKEN_LINK:
          _brokenLinkDetected(event.payload as String?);
          break;

        case DatalinkConstants.MESSAGE_EVENT:
          _processAodvMsgReceived(event.payload as MessageAdHoc);
          break;

        case DatalinkConstants.DEVICE_INFO_BLE:
          List<dynamic> info = event.payload as List<dynamic>;
          _ownMac = info[0] as String;
          _ownName = info[1] as String;
          break;

        case DatalinkConstants.DEVICE_INFO_WIFI: // TODO: Always select this/identifier
          List<dynamic> info = event.payload as List<dynamic>;
          _ownMac = info[0] as String;
          _ownName = info[1] as String;
          break;

        default:
          // Notify upper layer of ad hoc events occuring in lower layers
          _controller.add(event);
          break;
      }
    });
  }

  /// Display in the log console the routing table after a DELAY in ms and every
  /// PERIOD times.
  void _initTimerDebugRIB() {
    Timer.periodic(
      Duration(milliseconds: AodvConstants.PERIOD), 
      (Timer timer) {
        Future.delayed(
          Duration(milliseconds: AodvConstants.DELAY), () => _displayRoutingTable()
        );
      }
    );
  }

  /// Display the routing table in the log console.
  void _displayRoutingTable() {
    bool display = false;
    StringBuffer buffer = new StringBuffer();

    if (_aodvHelper.getEntrySet().length > 0) {
      display = true;

      buffer.write('--------Routing Table:--------\n');
      for (final MapEntry<String?, EntryRoutingTable?> entry in _aodvHelper.getEntrySet()) {
        buffer..write(entry.value.toString())..write('\n');
      }
    }

    if (_mapDestSeqNum.length > 0) {
      display = true;
      buffer.write('--------SequenceNumber:--------\n');
      for (final MapEntry<String?, int?> entry in _mapDestSeqNum.entries) {
        buffer
          ..write(entry.key)..write(' -> ')
          ..write(entry.value.toString())..write('\n');
      }
    }

    if (display)
      print(buffer.toString());
  }

  /// Detects broken links to remote node label [remoteNode].
  void _brokenLinkDetected(String? remoteNode) {
    // Send RRER to precursors to notify that a remote node has disconnected
    if (_aodvHelper.sizeRoutingTable() > 0) {
      if (_verbose) log(TAG, 'Send RRER');
      _sendRRER(remoteNode!);
    }

    // Check if this node contains the remote node label
    if (_aodvHelper.containsDest(remoteNode)) {
      if (_verbose) log(TAG, 'Remove $remoteNode from RIB');
      _aodvHelper.removeEntry(remoteNode);
    }
  }

  /// Sends a ad hoc message [message] to the remote destination [address].
  void _send(MessageAdHoc message, String address) {
    if (_datalinkManager.isDirectNeighbors(address)) {
      EntryRoutingTable? destNext = _aodvHelper.getNextfromDest(address);
      if (destNext != null && message.header!.messageType == AodvConstants.DATA)
        destNext.updateDataPath(address);

      _sendDirect(message, address);
    } else if (_aodvHelper.containsDest(address)) {
      EntryRoutingTable? destNext = _aodvHelper.getNextfromDest(address);
      if (destNext == null) {
        if (_verbose) 
          log(TAG, 'No destNext found in the routing Table for $address');
      } else {
        if (_verbose) 
          log(TAG, 'Routing table contains ${destNext.next}');

        if (message.header!.messageType == AodvConstants.DATA)
          destNext.updateDataPath(address);

        _sendDirect(message, destNext.next);
      }
    } else if (message.header!.messageType == AodvConstants.RERR) {
      if (_verbose) log(TAG, 'RERR sent');
    } else {
      _dataMessage = message;

      _getNextSequenceNumber();

      _startTimerRREQ(
        address, AodvConstants.RREQ_RETRIES, AodvConstants.NET_TRANVERSAL_TIME
      );
    }
  }

  /// Sends an ad hoc [message] directly to a remote [address]
  void _sendDirect(MessageAdHoc message, String address) {
    if (_verbose) log(TAG, 'Send directly to $address');

    _datalinkManager.sendMessage(message, address);
  }

  /// Adds a the name of a precursor [precursorName] to the list of 
  /// precursor of a node.
  /// 
  /// Returns a list of [String] of precursors.
  List<String> _addPrecursors(String? precursorName) {
    return List<String>.empty(growable: true)..add(precursorName!);
  }

  /// Gets a destination sequence number from its destination [dest].
  /// 
  /// Returns the destination sequence number.
  int _getDestSequenceNumber(String? dest) {
    if (_mapDestSeqNum.containsKey(dest))
      return _mapDestSeqNum[dest]!;
    return AodvConstants.UNKNOWN_SEQUENCE_NUMBER;
  }

  /// Increments the sequence number
  void _getNextSequenceNumber() {
    if (_ownSequenceNum < AodvConstants.MAX_VALID_SEQ_NUM) {
      _ownSequenceNum = _ownSequenceNum + 1;
    } else {
      _ownSequenceNum = AodvConstants.MIN_VALID_SEQ_NUM;
    }
  }

  /// Associates a destination sequence number [seqNum] with its destination
  /// [dest].
  void _saveDestSequenceNumber(String dest, int seqNum) {
    _mapDestSeqNum.putIfAbsent(dest, () => seqNum);
  }

/*----------------------------------- RREQ -----------------------------------*/

  /// Send a RREQ message to find a remote destination [destAddr]. A timer is
  /// executed [retry] times every [time] ms.
  /// 
  /// First value of retry and time should be set respectively to RREQ_RETRIES 
  /// and NET_TRANVERSAL_TIME.
  /// 
  /// Throws an [AodvMessageException] is the destination is not found
  /// within the given attempts
  void _startTimerRREQ(String? destAddr, int retry, int time) {
    if (_verbose) log(TAG, 'No connection to $destAddr -> send RREQ message');

    // Contruct the RREQ message
    MessageAdHoc message = MessageAdHoc(
      Header(messageType: AodvConstants.RREQ, 
        label: _ownLabel,
        name: _ownName,
        mac: _ownMac
      ),
      RREQ(
        AodvConstants.RREQ, AodvConstants.INIT_HOP_COUNT, 
        _aodvHelper.getIncrementRreqId(), _getDestSequenceNumber(destAddr), 
        destAddr!, _ownSequenceNum, _ownLabel
      )
    );

    // Broadcast RREQ message to all directly connected devices
    _datalinkManager.broadcast(message);

    // Start the timer
    Timer(Duration(milliseconds: time), () {
      EntryRoutingTable? entry = _aodvHelper.getNextfromDest(destAddr);
      if (entry == null) {
        if (retry == 0) {
          // The destination has not been found after all the attempts
          _controller.add(AdHocEvent(
            DatalinkConstants.INTERNAL_EXCEPTION,
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

  /// Processes an ad hoc [message] of type RREQ.
  void _processRREQ(MessageAdHoc message) {
    RREQ rreq = RREQ.fromJson((message.pdu as Map) as Map<String, dynamic>);
    int? hop = rreq.hopCount;
    String? originateAddr = message.header!.label;
    if (_verbose) log(TAG, 'Received RREQ from $originateAddr');

    if (rreq.destAddress.compareTo(_ownLabel) == 0) {
      _saveDestSequenceNumber(rreq.originAddress, rreq.originSequenceNum);

      if (_verbose) 
        log(TAG, '$_ownLabel is the destination (stop RREQ broadcast)');

      EntryRoutingTable? entry = _aodvHelper.addEntryRoutingTable(
        rreq.originAddress, originateAddr!, hop, rreq.originSequenceNum, 
        AodvConstants.NO_LIFE_TIME, []
      );

      if (entry != null) {
        if (rreq.destSequenceNum > _ownSequenceNum)
          _getNextSequenceNumber();

        RREP rrep = RREP(
          AodvConstants.RREP, AodvConstants.INIT_HOP_COUNT, rreq.originAddress, 
          _ownSequenceNum, _ownLabel, AodvConstants.LIFE_TIME
        );

        if (_verbose) log(TAG, 'Destination reachable via ${entry.next}');

        _send(
          MessageAdHoc(
            Header(
              messageType: AodvConstants.RREP, 
              label: _ownLabel, 
              name: _ownName,
              mac: _ownMac
            ),
            rrep
          ),
          entry.next
        );

        _timerFlushReverseRoute(rreq.originAddress, rreq.originSequenceNum);
      }
    } else if (_aodvHelper.containsDest(rreq.destAddress)) {
      _sendRREP_GRATUITOUS(message.header!.label, rreq);
    } else {
      if (rreq.originAddress.compareTo(_ownLabel) == 0) {
        if (_verbose) log(TAG, 'Reject own RREQ ${rreq.originAddress}');
      } else if (_aodvHelper.addBroadcastId(rreq.originAddress, rreq.rreqId)) {
        rreq.incrementHopCount();
        message.header = Header(
          messageType: AodvConstants.RREQ, 
          label: _ownLabel,
          name: _ownName,
          mac: _ownMac
        );
        message.pdu = rreq;

        _datalinkManager.broadcastExcept(message, originateAddr);

        _aodvHelper.addEntryRoutingTable(
          rreq.originAddress, originateAddr!, hop, rreq.originSequenceNum, 
          AodvConstants.NO_LIFE_TIME, []
        );

        _timerFlushReverseRoute(rreq.originAddress, rreq.originSequenceNum);
      } else {
        if (_verbose) log(TAG, 'Already received this RREQ from ${rreq.originAddress}');
      }
    }
  }

/*----------------------------------- RREP -----------------------------------*/

  /// Processes an ad hoc [message] of type RREP.
  void _processRREP(MessageAdHoc message) {
    RREP rrep = RREP.fromJson((message.pdu as Map) as Map<String, dynamic>);
    int? hopRcv = rrep.hopCount;
    String? nextHop = message.header!.label;

    if (_verbose) log(TAG, 'Received RREP from $nextHop');

    if (rrep.destAddress.compareTo(_ownLabel) == 0) {
      if (_verbose) log(TAG, '$_ownLabel is the destination (stop RREP)');
        _saveDestSequenceNumber(rrep.originAddress, rrep.sequenceNum);

        _aodvHelper.addEntryRoutingTable(
          rrep.originAddress, nextHop!, hopRcv, rrep.sequenceNum, rrep.lifetime, []
        );

        Data data = _dataMessage!.pdu as Data;
        _send(_dataMessage!, data.destAddress!);

        _timerFlushForwardRoute(rrep.originAddress, rrep.sequenceNum, rrep.lifetime);
    } else {
      EntryRoutingTable? destNext = _aodvHelper.getNextfromDest(rrep.destAddress);
      if (destNext == null) {
        throw AodvUnknownDestException(
          'No destNext found in the routing Table for ${rrep.destAddress}'
        );
      } else {
        if (_verbose) log(TAG, 'Destination reachable via ${destNext.next}');

        rrep.incrementHopCount();
        _send(
          MessageAdHoc(
            Header(
              messageType: AodvConstants.RREP, 
              label: _ownLabel,
              name: _ownName,
              mac: _ownMac
            ), 
            rrep),
          destNext.next
        );

        _aodvHelper.addEntryRoutingTable(
          rrep.originAddress, nextHop!, hopRcv, rrep.sequenceNum, rrep.lifetime, 
          _addPrecursors(destNext.next)
        );

        _timerFlushForwardRoute(rrep.originAddress, rrep.sequenceNum, rrep.lifetime);
      }
    }
  }

/*----------------------------- RREP_GRATUITOUS -----------------------------*/

  void _sendRREP_GRATUITOUS(String? senderAddr, RREQ rreq) {
    EntryRoutingTable entry = _aodvHelper.getDestination(rreq.destAddress)!;

    entry.updatePrecursors(senderAddr!);

    _aodvHelper.addEntryRoutingTable(
      rreq.originAddress, senderAddr, rreq.hopCount, rreq.originSequenceNum, 
      AodvConstants.NO_LIFE_TIME, _addPrecursors(entry.next)
    );

    _timerFlushReverseRoute(rreq.originAddress, rreq.originSequenceNum);

    RREP rrep = RREP(
      AodvConstants.RREP_GRATUITOUS, rreq.hopCount, rreq.destAddress, 
      _ownSequenceNum, rreq.originAddress, AodvConstants.LIFE_TIME
    );

    _send(
      MessageAdHoc(
        Header(
          messageType: AodvConstants.RREP_GRATUITOUS,
          label: _ownLabel,
          name: _ownName,
          mac: _ownMac
        ), 
        rrep
      ), 
      entry.next
    );

    if (_verbose) log(TAG, 'Send Gratuitous RREP to ${entry.next}');

    rrep = RREP(AodvConstants.RREP, entry.hop+ 1, rreq.originAddress, 
      entry.destSeqNum, entry.destAddress, AodvConstants.LIFE_TIME
    );

    _send(
      MessageAdHoc(
        Header(
          messageType: AodvConstants.RREP,
          label: _ownLabel,
          name: _ownName,
          mac: _ownMac
        ),
        rrep),
      rreq.originAddress
    );

    if (_verbose) log(TAG, 'Send RREP to ${rreq.originAddress}');
  }

  /// Processes an ad hoc [message] of type RREP_GRATUITOUS.
  void _processRREP_GRATUITOUS(MessageAdHoc message) {
    RREP rrep = RREP.fromJson((message.pdu as Map) as Map<String, dynamic>);
    int hopCount = rrep.incrementHopCount();

    if (rrep.destAddress.compareTo(_ownLabel) == 0) {
      if (_verbose) log(TAG, '$_ownLabel is the destination (stop RREP)');

      _aodvHelper.addEntryRoutingTable(
        rrep.originAddress, message.header!.label!, hopCount, rrep.sequenceNum, 
        rrep.lifetime, []
      );

      _timerFlushReverseRoute(rrep.originAddress, rrep.sequenceNum);
    } else {
      EntryRoutingTable? destNext = _aodvHelper.getNextfromDest(rrep.destAddress);
      if (destNext == null) {
        throw AodvUnknownDestException(
          'No destNext found in the routing Table for ${rrep.destAddress}'
        );
      } else {
        if (_verbose) log(TAG, 'Destination reachable via ${destNext.next}');
        
        _aodvHelper.addEntryRoutingTable(
          rrep.originAddress, message.header!.label!, hopCount, rrep.sequenceNum, 
          rrep.lifetime, _addPrecursors(destNext.next));

        _timerFlushReverseRoute(rrep.originAddress, rrep.sequenceNum);

        message.header = Header(
          messageType: AodvConstants.RREP_GRATUITOUS,
          label: _ownLabel,
          name: _ownName,
          mac: _ownMac
        );

        _send(message, destNext.next);
      }
    }
  }

/*----------------------------------- RERR -----------------------------------*/

  /// Sends a RRER message when a connection closed from a remote node of label
  /// [brokenNodeAddress] has been detected.
  void _sendRRER(String brokenNodeAddress) {
    if (_aodvHelper.containsNext(brokenNodeAddress)) {
      String dest = _aodvHelper.getDestFromNext(brokenNodeAddress)!;
      if (dest.compareTo(_ownLabel) == 0) {
        if (_verbose) 
          log(TAG, 'RERR received on the destination (stop forward)');
      } else {
        // Create the RERR message to send
        RERR rrer = RERR(AodvConstants.RERR, dest, _ownSequenceNum);
        // Send the RERR message to all precursors
        List<String?> precursors = _aodvHelper.getPrecursorsFromDest(dest);
        if (precursors.isNotEmpty) {
          for (String? precursor in precursors) {
            if (_verbose) log(TAG, 'send RERR to $precursor');

            _send(
              MessageAdHoc(
                Header(
                  messageType: AodvConstants.RERR, 
                  label: _ownLabel, 
                  name: _ownName,
                  mac: _ownMac
                ),
                rrer
              ),
              precursor!
            );
          }
        }

        // Remove the destination from the routing table
        _aodvHelper.removeEntry(dest);
      }
    }
  }

  /// Processes an ad hoc [message] of type RERR.
  void _processRERR(MessageAdHoc message) {
    // Get the RERR message
    RERR rerr = RERR.fromJson((message.pdu as Map) as Map<String, dynamic>);
    // Get previous source address
    String? originateAddr = message.header!.label;

    if (_verbose) 
      log(TAG, 
        'Received RERR from $originateAddr ->' 
        + 'Node ${rerr.unreachableDestAddress} is unreachable'
      );

    if (rerr.unreachableDestAddress.compareTo(_ownLabel) == 0) {
      if (_verbose) log(TAG, 'RERR received on the destination (stop forward)');
    } else if (_aodvHelper.containsDest(rerr.unreachableDestAddress)) {
      // Update header of the message
      message.header = Header(
        messageType: AodvConstants.RERR, 
        label: _ownLabel, 
        name: _ownName,
        mac: _ownMac
      );
        
      // Send to precursors
      List<String?> precursors = 
        _aodvHelper.getPrecursorsFromDest(rerr.unreachableDestAddress);

      if (precursors.isNotEmpty) {
        for (String? precursor in precursors) {
          if (_verbose) log(TAG, ' Precursor: $precursor');
            _send(message, precursor!);
        }
      } else {
        if (_verbose) log(TAG, 'No precursors');
      }

      // Remove the entry
      _aodvHelper.removeEntry(rerr.unreachableDestAddress);
    } else {
      if (_verbose) 
        log(TAG, 'Node does not contain dest: ${rerr.unreachableDestAddress}');
    }
  }

/*----------------------------------- DATA -----------------------------------*/

  /// Processes an ad hoc [message] of type DATA.
  /// 
  /// Throws an [AodvUnknownDestException] if the destination is not found.
  void _processData(MessageAdHoc message) {
    // Get the DATA message
    Data data = Data.fromJson((message.pdu as Map) as Map<String, dynamic>);

    if (_verbose) 
      log(TAG, 'Data message received from: ${message.header!.label}');

    if (data.destAddress!.compareTo(_ownLabel) == 0) {
      if (_verbose) 
        log(TAG, _ownLabel + ' is the destination (stop DATA message)');

      print(message);

      // Get the header of the message
      Header header = message.header!;
      // Get the AdHocDevice object of the sender
      AdHocDevice device = AdHocDevice(
        label: header.label,
        name: header.name,
        mac: header.mac,
        type: header.deviceType!
      );

      // Notify upper layer of the data received
      _controller.add(
        AdHocEvent(DatalinkConstants.DATA_RECEIVED, [device, data.payload])
      );
    } else {
      // Forward the DATA message to the destination with regards to the routing 
      // table
      EntryRoutingTable? destNext = _aodvHelper.getNextfromDest(data.destAddress);
      if (destNext == null) {
        throw AodvUnknownDestException(
          'No destNext found in the routing Table for ${data.destAddress}'
        );
      } else {
        if (_verbose) log(TAG, 'Destination reachable via ${destNext.next}');
        // Get the header of the message
        Header header = message.header!;
        // Get the AdHocDevice object of the sender
        AdHocDevice device = AdHocDevice(
          label: header.label,
          name: header.name,
          mac: header.mac,
          type: header.deviceType!
        );

        // Notify upper layer of the data to be forwarded
        _controller.add(
          AdHocEvent(DatalinkConstants.FORWARD_DATA, [device, data.payload])
        );

        // Update the data path
        destNext.updateDataPath(data.destAddress!);
        // Send the message to the next destination
        _send(message, destNext.next);
      }
    }
  }

/*----------------------------- Route Management -----------------------------*/

  void _timerFlushForwardRoute(String? destAddress, int seqNum, int lifeTime) {
    Timer(Duration(milliseconds: lifeTime),
      () {
        if (_verbose) { 
          log(TAG, 
            'Add timer for $destAddress - seq: $seqNum - lifeTime: $lifeTime'
          );
        }

        int lastChanged = _aodvHelper.getDataPathFromAddress(destAddress);
        int difference = (DateTime.now().millisecond - lastChanged);

        if (lastChanged == 0) {
          _aodvHelper.removeEntry(destAddress);

          if (_verbose)
            log(TAG, 'No Data on $destAddress');
        } else if (difference < lifeTime) {
          _timerFlushForwardRoute(destAddress, seqNum, lifeTime);
        } else {
          _aodvHelper.removeEntry(destAddress);
          if (_verbose) log(TAG, 'No Data on $destAddress since $difference');
        }
      }
    );
  }

  void _timerFlushReverseRoute(String? originAddress, int seqNum) {
    Timer(Duration(milliseconds: AodvConstants.EXPIRED_TABLE),
      () {
        if (_verbose)
          log(TAG, 'Add timer for $originAddress - seq: $seqNum');

        int lastChanged = _aodvHelper.getDataPathFromAddress(originAddress);
        int difference = (DateTime.now().millisecond - lastChanged);

        if (lastChanged == 0) {
          _aodvHelper.removeEntry(originAddress);

          if (_verbose) 
            log(TAG, 'No Data on $originAddress');
        } else if (difference < AodvConstants.EXPIRED_TIME) {
          _timerFlushReverseRoute(originAddress, seqNum);
        } else {
          _aodvHelper.removeEntry(originAddress);

          if (_verbose) 
            log(TAG, 'No Data on $originAddress since $difference');
        }
      }
    );
  }

  /// Processes an ad hoc [message] related to the AODV protocol.
  ///
  /// Throws an [AodvUnknownDestException] for unknown destination problem.
  /// Throws an [AodvUnknownTypeException] for unknown AODV message type.
  void _processAodvMsgReceived(MessageAdHoc message) {
    switch (message.header!.messageType) {
      case AodvConstants.RREQ:
        _processRREQ(message);
        _getNextSequenceNumber();
        break;

      case AodvConstants.RREP:
        _processRREP(message);
        _getNextSequenceNumber();
        break;

      case AodvConstants.RREP_GRATUITOUS:
        _processRREP_GRATUITOUS(message);
        _getNextSequenceNumber();
        break;

      case AodvConstants.RERR:
        _processRERR(message);
        _getNextSequenceNumber();
        break;

      case AodvConstants.DATA:
        _processData(message);
        break;

      default:
        throw AodvUnknownTypeException('Unknown AODV Type');
    }
  }
}
