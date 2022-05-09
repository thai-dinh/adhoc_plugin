import 'dart:async';
import 'dart:collection';

import 'package:adhoc_plugin/src/appframework/config.dart';
import 'package:adhoc_plugin/src/datalink/service/adhoc_device.dart';
import 'package:adhoc_plugin/src/datalink/service/adhoc_event.dart';
import 'package:adhoc_plugin/src/datalink/service/constants.dart';
import 'package:adhoc_plugin/src/datalink/utils/identifier.dart';
import 'package:adhoc_plugin/src/datalink/utils/msg_adhoc.dart';
import 'package:adhoc_plugin/src/datalink/utils/msg_header.dart';
import 'package:adhoc_plugin/src/datalink/utils/utils.dart';
import 'package:adhoc_plugin/src/network/aodv/aodv_helper.dart';
import 'package:adhoc_plugin/src/network/aodv/constants.dart' as aodv;
import 'package:adhoc_plugin/src/network/aodv/data.dart';
import 'package:adhoc_plugin/src/network/aodv/rerr.dart';
import 'package:adhoc_plugin/src/network/aodv/rrep.dart';
import 'package:adhoc_plugin/src/network/aodv/rreq.dart';
import 'package:adhoc_plugin/src/network/datalinkmanager/constants.dart'
    as datalink;
import 'package:adhoc_plugin/src/network/datalinkmanager/datalink_manager.dart';
import 'package:adhoc_plugin/src/network/exceptions/aodv_message.dart';
import 'package:adhoc_plugin/src/network/exceptions/aodv_unknown_dest.dart';
import 'package:adhoc_plugin/src/network/exceptions/aodv_unknown_type.dart';
import 'package:adhoc_plugin/src/presentation/constants.dart';
import 'package:adhoc_plugin/src/presentation/key_mgnmt/certificate_repository.dart';
import 'package:flutter/foundation.dart';

/// Class representing the core of the AODV protocol. It manages all the
/// messages received and to send.
///
/// NOTE: Most of the following source code has been borrowed and adapted from
/// the original codebase provided by Gaulthier Gain, which can be found at:
/// https://github.com/gaulthiergain/AdHocLib
class AodvManager {
  static const String TAG = '[AodvManager]';

  final bool _verbose;

  MessageAdHoc? _dataMessage;

  late Identifier _ownMac;
  late String _ownName;
  late String _ownLabel;
  late int _ownSequenceNum;
  late AodvHelper _aodvHelper;
  late DataLinkManager _datalinkManager;
  late HashMap<String?, int?> _mapDestSeqNum;
  late StreamController<AdHocEvent> _controller;
  late final CertificateRepository _repository;

  /// Creates a [AodvManager] object.
  ///
  /// The debug/verbose mode is set if [_verbose] is true.
  ///
  /// A certificate repository [_repository] is used to manage certificates
  /// of source node to destination node including the intermediate nodes. It is
  /// used for the chain discovery process.
  ///
  /// This object is configured according to [config], which contains specific
  /// configurations.
  AodvManager(this._verbose, this._repository, Config config) {
    _ownMac = Identifier();
    _ownName = '';
    _ownLabel = config.label;
    _ownSequenceNum = aodv.FIRST_SEQUENCE_NUMBER;
    _aodvHelper = AodvHelper(_verbose);
    _datalinkManager = DataLinkManager(_verbose, config);
    _mapDestSeqNum = HashMap();
    _controller = StreamController<AdHocEvent>.broadcast();
    _initialize();
    if (_verbose) {
      // Periodical display of the routing table
      _initTimerDebugRIB();
    }
  }

/*------------------------------Getters & Setters-----------------------------*/

  /// Returns the label as [String] of the current node.
  String get label => _ownLabel;

  /// Returns the [DataLinkManager] instance used by this AODV manager.
  DataLinkManager get dataLinkManager => _datalinkManager;

  /// Returns a [Stream] of [AdHocEvent] events of lower layers.
  Stream<AdHocEvent> get eventStream => _controller.stream;

/*------------------------------Public methods-------------------------------*/

  /// Sends a message with payload as [pdu] to a remote [address].
  void sendMessageTo(String address, Object pdu) {
    // Create the header of the message
    var header = Header(
      messageType: aodv.DATA,
      label: _ownLabel,
      name: _ownName,
      mac: _ownMac,
    );

    _send(MessageAdHoc(header, Data(address, pdu)), address);
  }

/*-----------------------------Private methods-------------------------------*/

  /// Initializes the listening process of lower layer streams.
  void _initialize() {
    _datalinkManager.eventStream.listen((event) {
      switch (event.type) {
        case datalink.BROKEN_LINK:
          _brokenLinkDetected(event.payload as String?);
          break;

        case datalink.MESSAGE_EVENT:
          _processAodvMsgReceived(event.payload as MessageAdHoc);
          break;

        case DEVICE_INFO_BLE:
          var info = event.payload as List<dynamic>;
          _ownMac.ble = info[0] as String;
          _ownName = info[1] as String;
          break;

        case DEVICE_INFO_WIFI:
          var info = event.payload as List<dynamic>;
          _ownMac.wifi = info[0] as String;
          _ownName = info[1] as String;
          break;

        default:
          // Notify upper layer of ad hoc events occuring in lower layers
          _controller.add(event);
      }
    });
  }

  /// Displays in the log console the routing table after a DELAY in ms and every
  /// PERIOD times.
  void _initTimerDebugRIB() {
    Timer.periodic(Duration(milliseconds: aodv.PERIOD), (timer) {
      Future.delayed(Duration(milliseconds: aodv.DELAY), _displayRoutingTable);
    });
  }

  /// Displays the routing table in the log console.
  void _displayRoutingTable() {
    var display = false;
    var buffer = StringBuffer();

    if (_aodvHelper.getEntrySet().isNotEmpty) {
      display = true;

      buffer.write('--------Routing Table:--------\n');
      for (final entry in _aodvHelper.getEntrySet()) {
        buffer..write(entry.value.toString())..write('\n');
      }
    }

    if (_mapDestSeqNum.isNotEmpty) {
      display = true;
      buffer.write('--------SequenceNumber:--------\n');
      for (final entry in _mapDestSeqNum.entries) {
        buffer
          ..write(entry.key)
          ..write(' -> ')
          ..write(entry.value.toString())
          ..write('\n');
      }
    }

    if (display) {
      debugPrint(buffer.toString());
    }
  }

  /// Detects broken links to remote node label [remoteNode].
  void _brokenLinkDetected(String? remoteNode) {
    // Send RERR to precursors to notify that a remote node has disconnected
    if (_aodvHelper.sizeRoutingTable() > 0) {
      if (_verbose) log(TAG, 'Send RERR');
      _sendRERR(remoteNode!);
    }

    // Check if this node contains the remote node label
    if (_aodvHelper.containsDest(remoteNode!)) {
      if (_verbose) log(TAG, 'Remove $remoteNode from RIB');
      _aodvHelper.removeEntry(remoteNode);
    }
  }

  /// Sends an ad hoc message [message] to the remote destination [address].
  void _send(MessageAdHoc message, String address) {
    if (_datalinkManager.isDirectNeighbor(address)) {
      var destNext = _aodvHelper.getNextfromDest(address);
      if (destNext != null && message.header.messageType == aodv.DATA) {
        // Update the data path
        destNext.updateDataPath(address);
      }

      _sendDirect(message, address);
    } else if (_aodvHelper.containsDest(address)) {
      // Destination learned from neighbors so send to next by checking routing
      // table
      var destNext = _aodvHelper.getNextfromDest(address);
      if (destNext == null) {
        if (_verbose) {
          log(TAG, 'No destNext found in the routing Table for $address');
        }
      } else {
        if (_verbose) {
          log(TAG, 'Routing table contains ${destNext.next}');
        }

        if (message.header.messageType == aodv.DATA) {
          // Update the data path
          destNext.updateDataPath(address);
        }

        // Send to direct neighbor
        _sendDirect(message, destNext.next);
      }
    } else if (message.header.messageType == aodv.RERR) {
      if (_verbose) log(TAG, 'RERR sent');
    } else {
      _dataMessage = message;

      // Increment sequence number prior to insertion in RREQ
      _getNextSequenceNumber();

      _startTimerRREQ(address, aodv.RREQ_RETRIES, aodv.NET_TRANVERSAL_TIME);
    }
  }

  /// Sends an ad hoc [message] directly to a remote [address]
  void _sendDirect(MessageAdHoc message, String address) {
    if (_verbose) log(TAG, 'Send directly to $address');

    _datalinkManager.sendMessage(address, message);
  }

  /// Adds a the name of a precursor [precursorName] to the list of
  /// precursor of a node.
  ///
  /// Returns a list of [String] of precursors.
  List<String> _addPrecursor(String? precursorName) {
    return List<String>.empty(growable: true)..add(precursorName!);
  }

  /// Gets a destination sequence number from its destination [dest].
  ///
  /// Returns the destination sequence number.
  int _getDestSequenceNumber(String? dest) {
    if (_mapDestSeqNum.containsKey(dest)) {
      return _mapDestSeqNum[dest]!;
    }

    return aodv.UNKNOWN_SEQUENCE_NUMBER;
  }

  /// Increments the sequence number
  void _getNextSequenceNumber() {
    if (_ownSequenceNum < aodv.MAX_VALID_SEQ_NUM) {
      _ownSequenceNum = _ownSequenceNum + 1;
    } else {
      _ownSequenceNum = aodv.MIN_VALID_SEQ_NUM;
    }
  }

  /// Associates a destination sequence number [seqNum] with its destination
  /// [dest].
  void _saveDestSequenceNumber(String dest, int seqNum) {
    _mapDestSeqNum.putIfAbsent(dest, () => seqNum);
  }

/*----------------------------------- RREQ -----------------------------------*/

  /// Send a [RREQ] message to find a remote destination [destAddr]. A timer is
  /// executed [retry] times every [time] ms.
  ///
  /// First value of retry and time should be respectively set to RREQ_RETRIES
  /// and NET_TRANVERSAL_TIME.
  ///
  /// Throws an [AodvMessageException] is the destination is not found
  /// within the given attempts.
  void _startTimerRREQ(String destAddr, int retry, int time) {
    if (_verbose) log(TAG, 'No connection to $destAddr -> send RREQ message');

    // Contruct the RREQ message
    var message = MessageAdHoc(
        Header(
            messageType: aodv.RREQ,
            label: _ownLabel,
            name: _ownName,
            mac: _ownMac),
        RREQ(
            aodv.RREQ,
            aodv.INIT_HOP_COUNT,
            _aodvHelper.getIncrementRreqId(),
            _getDestSequenceNumber(destAddr),
            destAddr,
            _ownSequenceNum,
            _ownLabel,
            aodv.TTL[retry],
            List.empty(growable: true)));

    // Broadcast RREQ message to all directly connected devices
    _datalinkManager.broadcast(message);

    // Start the timer
    Timer(Duration(milliseconds: time), () {
      var entry = _aodvHelper.getNextfromDest(destAddr);
      if (entry == null) {
        if (retry == 0) {
          // The destination has not been found after all the attempts
          _controller.add(AdHocEvent(
              INTERNAL_EXCEPTION,
              AodvMessageException(
                  'Unable to establish a communication with: $destAddr')));
        } else {
          _startTimerRREQ(destAddr, retry - 1, time * 2);
        }
      }
    });
  }

  /// Processes an ad hoc [message] of type [RREQ].
  void _processRREQ(MessageAdHoc message) {
    // Get the RREQ message
    var rreq = RREQ.fromJson((message.pdu as Map) as Map<String, dynamic>);
    // Get previous hop and previous address
    var hop = rreq.hopCount;
    String? originateAddr = message.header.label;

    if (_verbose) log(TAG, 'Received RREQ from $originateAddr');

    if (rreq.dstAddr.compareTo(_ownLabel) == 0) {
      // Save the destination sequence number
      _saveDestSequenceNumber(rreq.srcAddr, rreq.srcSeqNum);

      if (_verbose) {
        log(TAG, '$_ownLabel is the destination (stop RREQ broadcast)');
      }

      // Notify upper layer of the certificate chain received
      _controller.add(AdHocEvent(CERT_REP, rreq.chain));

      // Update routing table
      var entry = _aodvHelper.addEntryRoutingTable(rreq.srcAddr, originateAddr,
          hop, rreq.srcSeqNum, aodv.NO_LIFE_TIME, List.empty(growable: true));

      if (entry != null) {
        if (rreq.dstSeqNum > _ownSequenceNum) {
          // Destination node increments its sequence number when the
          // sequence number in RREQ is equal to its stored number
          _getNextSequenceNumber();
        }

        // Generate RREP to be sent
        var rrep = RREP(
            aodv.RREP,
            aodv.INIT_HOP_COUNT,
            rreq.srcAddr,
            _ownSequenceNum,
            _ownLabel,
            aodv.LIFE_TIME,
            List.empty(growable: true));

        if (_verbose) log(TAG, 'Destination reachable via ${entry.next}');

        // Send RREP to next destination
        _send(
            MessageAdHoc(
                Header(
                    messageType: aodv.RREP,
                    label: _ownLabel,
                    name: _ownName,
                    mac: _ownMac),
                rrep),
            entry.next);

        // Trigger timer for this reverse route
        _timerFlushReverseRoute(rreq.srcAddr, rreq.srcSeqNum);
      }
    } else if (_aodvHelper.containsDest(rreq.dstAddr)) {
      // Send RREP GRATUITOUS to destination
      _sendRREP_GRATUITOUS(message.header.label, rreq);
    } else {
      if (rreq.srcAddr.compareTo(_ownLabel) == 0) {
        if (_verbose) log(TAG, 'Reject own RREQ ${rreq.srcAddr}');
      } else if (_aodvHelper.addBroadcastId(rreq.srcAddr, rreq.rreqId)) {
        // Decrement TTL & check its value
        rreq.decrementTTL();
        if (rreq.ttl == 0) {
          return;
        }

        // Update PDU and header
        rreq.incrementHopCount();
        message.pdu = rreq;
        message.header = Header(
            messageType: aodv.RREQ,
            label: _ownLabel,
            name: _ownName,
            mac: _ownMac);

        // Broadcast RREQ to direct neighbors
        _datalinkManager.broadcastExcept(message, originateAddr);

        // Update routing table
        _aodvHelper.addEntryRoutingTable(rreq.srcAddr, originateAddr, hop,
            rreq.srcSeqNum, aodv.NO_LIFE_TIME, []);

        // Trigger timer for this reverse route
        _timerFlushReverseRoute(rreq.srcAddr, rreq.srcSeqNum);
      } else {
        if (_verbose) {
          log(TAG, 'Already received this RREQ from ${rreq.srcAddr}');
        }
      }
    }
  }

/*----------------------------------- RREP -----------------------------------*/

  /// Processes an ad hoc [message] of type [RREP].
  void _processRREP(MessageAdHoc message) {
    // Get the RREP message
    var rrep = RREP.fromJson((message.pdu as Map) as Map<String, dynamic>);
    // Get previous hop and previous address
    var hopRcv = rrep.hopCount;
    var nextHop = message.header.label;

    if (_verbose) log(TAG, 'Received RREP from $nextHop');

    if (rrep.dstAddr.compareTo(_ownLabel) == 0) {
      if (_verbose) log(TAG, '$_ownLabel is the destination (stop RREP)');
      // Notify the upper layer of the certificate chain received
      _controller.add(AdHocEvent(CERT_REP, rrep.chain));

      // Save the destination sequence number
      _saveDestSequenceNumber(rrep.srcAddr, rrep.seqNum);

      // Update routing table
      _aodvHelper.addEntryRoutingTable(
          rrep.srcAddr, nextHop, hopRcv, rrep.seqNum, rrep.lifetime, []);

      // Send data message to destination node
      var data = _dataMessage!.pdu as Data;
      _send(_dataMessage!, data.dstAddr!);

      // Trigger timer
      _timerFlushForwardRoute(rrep.srcAddr, rrep.seqNum, rrep.lifetime);
    } else {
      var destNext = _aodvHelper.getNextfromDest(rrep.dstAddr);
      if (destNext == null) {
        throw AodvUnknownDestException(
            'No destNext found in the routing Table for ${rrep.dstAddr}');
      } else {
        if (_verbose) log(TAG, 'Destination reachable via ${destNext.next}');

        // Add intermediate node certificate to the certificate chain
        rrep.chain.add(_repository.getCertificate(message.header.label)!);
        rrep.incrementHopCount();
        _send(
            MessageAdHoc(
                Header(
                    messageType: aodv.RREP,
                    label: _ownLabel,
                    name: _ownName,
                    mac: _ownMac),
                rrep),
            destNext.next);

        _aodvHelper.addEntryRoutingTable(rrep.srcAddr, nextHop, hopRcv,
            rrep.seqNum, rrep.lifetime, _addPrecursor(destNext.next));

        // Trigger timer
        _timerFlushForwardRoute(rrep.srcAddr, rrep.seqNum, rrep.lifetime);
      }
    }
  }

/*----------------------------- RREP_GRATUITOUS -----------------------------*/

  /// Sends a [RREP] gratuitous message to the source and destination nodes.
  ///
  /// The address of the source node is set to [senderAddr] and information
  /// needed for the [RREP] message are found in [rreq].
  void _sendRREP_GRATUITOUS(String senderAddr, RREQ rreq) {
    // Get entry in routing table for the destination
    var entry = _aodvHelper.getDestination(rreq.dstAddr)!;

    // Update the list of precursors
    entry.updatePrecursors(senderAddr);

    // Add routing table entry
    _aodvHelper.addEntryRoutingTable(rreq.srcAddr, senderAddr, rreq.hopCount,
        rreq.srcSeqNum, aodv.NO_LIFE_TIME, _addPrecursor(entry.next));

    // Trigger timer
    _timerFlushReverseRoute(rreq.srcAddr, rreq.srcSeqNum);

    // Generate gratuitous RREP for the next destination
    var rrep = RREP(
        aodv.RREP_GRATUITOUS,
        rreq.hopCount,
        rreq.dstAddr,
        _ownSequenceNum,
        rreq.srcAddr,
        aodv.LIFE_TIME,
        List.empty(growable: true));

    // Send gratuitous RREP message to the next destination
    _send(
        MessageAdHoc(
            Header(
                messageType: aodv.RREP_GRATUITOUS,
                label: _ownLabel,
                name: _ownName,
                mac: _ownMac),
            rrep),
        entry.next);

    if (_verbose) log(TAG, 'Send Gratuitous RREP to ${entry.next}');

    // Generate RREP message for the source
    rrep = RREP(aodv.RREP, entry.hop + 1, rreq.srcAddr, entry.dstSeqNum,
        entry.dstAddr, aodv.LIFE_TIME, List.empty(growable: true));

    // Send RREP message to the source
    _send(
        MessageAdHoc(
            Header(
                messageType: aodv.RREP,
                label: _ownLabel,
                name: _ownName,
                mac: _ownMac),
            rrep),
        rreq.srcAddr);

    if (_verbose) log(TAG, 'Send RREP to ${rreq.srcAddr}');
  }

  /// Processes an ad hoc [message] of type RREP_GRATUITOUS.
  void _processRREP_GRATUITOUS(MessageAdHoc message) {
    // Get the RREP message
    var rrep = RREP.fromJson((message.pdu as Map) as Map<String, dynamic>);
    // Get hop count
    var hopCount = rrep.incrementHopCount();

    if (rrep.dstAddr.compareTo(_ownLabel) == 0) {
      if (_verbose) log(TAG, '$_ownLabel is the destination (stop RREP)');

      // Update routing table
      _aodvHelper.addEntryRoutingTable(rrep.srcAddr, message.header.label,
          hopCount, rrep.seqNum, rrep.lifetime, []);

      // Trigger timer
      _timerFlushReverseRoute(rrep.srcAddr, rrep.seqNum);
    } else {
      var destNext = _aodvHelper.getNextfromDest(rrep.dstAddr);
      if (destNext == null) {
        throw AodvUnknownDestException(
            'No destNext found in the routing Table for ${rrep.dstAddr}');
      } else {
        if (_verbose) log(TAG, 'Destination reachable via ${destNext.next}');

        // Update routing table
        _aodvHelper.addEntryRoutingTable(rrep.srcAddr, message.header.label,
            hopCount, rrep.seqNum, rrep.lifetime, _addPrecursor(destNext.next));

        // Update header
        message.header = Header(
            messageType: aodv.RREP_GRATUITOUS,
            label: _ownLabel,
            name: _ownName,
            mac: _ownMac);

        // Send message to the next destination
        _send(message, destNext.next);

        // Trigger timer
        _timerFlushReverseRoute(rrep.srcAddr, rrep.seqNum);
      }
    }
  }

/*----------------------------------- RERR -----------------------------------*/

  /// Sends a [RERR] message when a connection closed from a remote node of label
  /// [brokenNodeAddress] has been detected.
  void _sendRERR(String brokenNodeAddress) {
    if (_aodvHelper.containsNext(brokenNodeAddress)) {
      var dest = _aodvHelper.getDestFromNext(brokenNodeAddress)!;
      if (dest.compareTo(_ownLabel) == 0) {
        if (_verbose) {
          log(TAG, 'RERR received on the destination (stop forward)');
        }
      } else {
        // Create the RERR message to send
        var rrer = RERR(aodv.RERR, dest, _ownSequenceNum);
        // Send the RERR message to all precursors
        var precursors = _aodvHelper.getPrecursorsFromDest(dest);
        if (precursors.isNotEmpty) {
          for (var precursor in precursors) {
            if (_verbose) log(TAG, 'send RERR to $precursor');

            _send(
                MessageAdHoc(
                    Header(
                        messageType: aodv.RERR,
                        label: _ownLabel,
                        name: _ownName,
                        mac: _ownMac),
                    rrer),
                precursor!);
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
    var rerr = RERR.fromJson((message.pdu as Map) as Map<String, dynamic>);
    // Get previous source address
    String? originateAddr = message.header.label;

    if (_verbose) {
      log(
          TAG,
          'Received RERR from $originateAddr ->' +
              'Node ${rerr.unreachableDstAddr} is unreachable');
    }

    if (rerr.unreachableDstAddr.compareTo(_ownLabel) == 0) {
      if (_verbose) log(TAG, 'RERR received on the destination (stop forward)');
    } else if (_aodvHelper.containsDest(rerr.unreachableDstAddr)) {
      // Update header of the message
      message.header = Header(
          messageType: aodv.RERR,
          label: _ownLabel,
          name: _ownName,
          mac: _ownMac);

      // Send to precursors
      var precursors =
          _aodvHelper.getPrecursorsFromDest(rerr.unreachableDstAddr);

      if (precursors.isNotEmpty) {
        for (var precursor in precursors) {
          if (_verbose) log(TAG, ' Precursor: $precursor');
          _send(message, precursor!);
        }
      } else {
        if (_verbose) log(TAG, 'No precursors');
      }

      // Remove the entry
      _aodvHelper.removeEntry(rerr.unreachableDstAddr);
    } else {
      if (_verbose) {
        log(TAG, 'Node does not contain dest: ${rerr.unreachableDstAddr}');
      }
    }
  }

/*----------------------------------- DATA -----------------------------------*/

  /// Processes an ad hoc [message] of type DATA.
  ///
  /// Throws an [AodvUnknownDestException] if the destination is not found.
  void _processData(MessageAdHoc message) {
    // Get the DATA message
    var data = Data.fromJson((message.pdu as Map) as Map<String, dynamic>);

    if (_verbose) {
      log(TAG, 'Data message received from: ${message.header.label}');
    }

    if (data.dstAddr!.compareTo(_ownLabel) == 0) {
      if (_verbose) {
        log(TAG, _ownLabel + ' is the destination (stop DATA message)');
      }

      // Get the header of the message
      var header = message.header;
      // Get the AdHocDevice object of the sender
      var device = AdHocDevice(
          label: header.label,
          name: header.name,
          mac: header.mac,
          type: header.deviceType!);

      // Notify upper layer of the data received
      _controller
          .add(AdHocEvent(datalink.DATA_RECEIVED, [device, data.payload]));
    } else {
      // Forward the DATA message to the destination with regards to the routing
      // table
      var destNext = _aodvHelper.getNextfromDest(data.dstAddr!);
      if (destNext == null) {
        throw AodvUnknownDestException(
            'No destNext found in the routing Table for ${data.dstAddr}');
      } else {
        if (_verbose) log(TAG, 'Destination reachable via ${destNext.next}');
        // Get the header of the message
        var header = message.header;
        // Get the AdHocDevice object of the sender
        var device = AdHocDevice(
            label: header.label,
            name: header.name,
            mac: header.mac,
            type: header.deviceType!);

        // Notify upper layer of the data to be forwarded
        _controller
            .add(AdHocEvent(datalink.FORWARD_DATA, [device, data.payload]));

        // Update the data path
        destNext.updateDataPath(data.dstAddr!);
        // Send the message to the next destination
        _send(message, destNext.next);
      }
    }
  }

/*----------------------------- Route Management -----------------------------*/

  /// Purges the forward entries of the routing table after [lifeTime] ms if
  /// no data is transmitted on a connection.
  ///
  /// The destination node of the connection is given by [dstAddr] and its
  /// sequence number by [seqNum].
  ///
  /// The variable 'lifeTime' should be set to LIFE_TIME ms.
  void _timerFlushForwardRoute(String dstAddr, int seqNum, int lifeTime) {
    Timer(Duration(milliseconds: lifeTime), () {
      if (_verbose) {
        log(TAG, 'Add timer for $dstAddr - seq: $seqNum - lifeTime: $lifeTime');
      }

      // Get the difference of time between the current time and the last time
      // where data has been transmitted
      var lastChanged = _aodvHelper.getDataPathFromAddress(dstAddr);
      var difference = (DateTime.now().millisecond - lastChanged);

      if (lastChanged == 0) {
        // If no data on the reverse route, delete it
        _aodvHelper.removeEntry(dstAddr);

        if (_verbose) {
          log(TAG, 'No Data on $dstAddr');
        }
      } else if (difference < lifeTime) {
        // Data on the path, restart the timer
        _timerFlushForwardRoute(dstAddr, seqNum, lifeTime);
      } else {
        // If no data on the reverse route, delete it
        _aodvHelper.removeEntry(dstAddr);
        if (_verbose) log(TAG, 'No Data on $dstAddr since $difference');
      }
    });
  }

  /// Purges the reverse entries of the routing table after EXPIRED_TABLE ms if
  /// no data is transmitted on a connection.
  ///
  /// The source node of the connection is given by [srcAddr] and its
  /// sequence number by [seqNum].
  ///
  /// The variable 'lifeTime' should be set to LIFE_TIME ms.
  void _timerFlushReverseRoute(String srcAddr, int seqNum) {
    Timer(Duration(milliseconds: aodv.EXPIRED_TABLE), () {
      if (_verbose) {
        log(TAG, 'Add timer for $srcAddr - seq: $seqNum');
      }

      // Get the difference of time between the current time and the last time
      // where data is transmitted
      var lastChanged = _aodvHelper.getDataPathFromAddress(srcAddr);
      var difference = (DateTime.now().millisecond - lastChanged);

      if (lastChanged == 0) {
        // If no data on the reverse route, delete it
        _aodvHelper.removeEntry(srcAddr);

        if (_verbose) {
          log(TAG, 'No Data on $srcAddr');
        }
      } else if (difference < aodv.EXPIRED_TIME) {
        // Data on the path, restart timer
        _timerFlushReverseRoute(srcAddr, seqNum);
      } else {
        // If no data on the reverse route, delete it
        _aodvHelper.removeEntry(srcAddr);

        if (_verbose) {
          log(TAG, 'No Data on $srcAddr since $difference');
        }
      }
    });
  }

  /// Processes an ad hoc [message] related to the AODV protocol.
  ///
  /// Throws an [AodvUnknownDestException] for unknown destination problem.
  /// Throws an [AodvUnknownTypeException] for unknown AODV message type.
  void _processAodvMsgReceived(MessageAdHoc message) {
    switch (message.header.messageType) {
      case aodv.RREQ:
        _processRREQ(message);
        _getNextSequenceNumber();
        break;

      case aodv.RREP:
        _processRREP(message);
        _getNextSequenceNumber();
        break;

      case aodv.RREP_GRATUITOUS:
        _processRREP_GRATUITOUS(message);
        _getNextSequenceNumber();
        break;

      case aodv.RERR:
        _processRERR(message);
        _getNextSequenceNumber();
        break;

      case aodv.DATA:
        _processData(message);
        break;

      default:
        throw AodvUnknownTypeException('Unknown AODV Type');
    }
  }
}
