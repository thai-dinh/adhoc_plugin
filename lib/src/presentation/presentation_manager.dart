import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/pointycastle.dart';

import 'certificate.dart';
import 'certificate_repository.dart';
import 'constants.dart';
import 'crypto_engine.dart';
import 'exceptions/verification_failed.dart';
import 'secure_data.dart';
import 'secure_group_controller.dart';
import '../appframework/config.dart';
import '../datalink/service/adhoc_device.dart';
import '../datalink/service/adhoc_event.dart';
import '../datalink/utils/utils.dart';
import '../network/aodv/aodv_manager.dart';
import '../network/datalinkmanager/constants.dart';
import '../network/datalinkmanager/datalink_manager.dart';


/// Class representing the core of the secure data layer. It performs 
/// certificates management as well as encryption and decryption tasks.  
class PresentationManager {
  static const String TAG = '[PresentationManager]';

  final bool _verbose;

  late CryptoEngine _engine;
  late AodvManager _aodvManager;
  late DataLinkManager _datalinkManager;
  late CertificateRepository _repository;
  late SecureGroupController _groupController;
  late StreamController<AdHocEvent> _controller;
  
  late HashMap<String, List<Object>> _buffer;
  late Set<String> _setFloodEvents;
  late int _validityPeriod;

  /// Creates a [PresentationManager] object.
  /// 
  /// The debug/verbose mode is set if [_verbose] is true.
  /// 
  /// This object is configured according to [config], which contains specific 
  /// configurations.
  PresentationManager(this._verbose, Config config) {
    this._repository = CertificateRepository(config);
    this._aodvManager = AodvManager(_verbose, _repository, config);
    this._datalinkManager = _aodvManager.dataLinkManager;
    this._engine = CryptoEngine();
    this._engine.initialize();
    this._groupController = SecureGroupController(
      _engine, _aodvManager, _datalinkManager, _aodvManager.eventStream, config
    );
    this._controller = StreamController<AdHocEvent>.broadcast();
    this._buffer = HashMap();
    this._setFloodEvents = Set();
    this._validityPeriod = config.validityPeriod;
    this._initialize();
  }

/*------------------------------Getters & Setters-----------------------------*/

  /// Secure group manager used by this instance.
  SecureGroupController get groupController => _groupController;

  /// Data-link manager used by the AODV manager.
  DataLinkManager get datalinkManager => _datalinkManager;

  /// List of direct neighbors.
  List<AdHocDevice> get directNeighbors => _datalinkManager.directNeighbors;

  /// Stream events of lower layers.
  Stream<AdHocEvent> get eventStream => _controller.stream;

/*------------------------------Public methods--------------------------------*/

  /// Sends an encrypted or unencrypted data message to a remote node.
  /// 
  /// The [data] of the message is encryped if [encrypted] is true, otherwise
  /// it is sent to node [destination] unencryped.
  void send(Object data, String destination, bool encrypted) async {
    if (_verbose) log(TAG, 'send() - encrypted: $encrypted');

    if (encrypted) {
      // Get the public certificate of the destination node
      Certificate? certificate = _repository.getCertificate(destination);
      if (certificate == null) {
        // Request certificate as it is not in the certificate repository
        // (Certificate Chain Discovery)
        _aodvManager.sendMessageTo(
          destination, SecureData(CERT_REQ, []).toJson()
        );

        // Buffer the encrypted message to send
        _buffer.update(
          destination, (msg) => msg..add(data), 
          ifAbsent: () => List.empty(growable: true)..add(data)
        );
        return;
      }

      // Encrypt data
      if (_verbose) log(TAG, 'send(): begin encryption');
      List<dynamic> encryptedData = await _engine.encrypt(
        Utf8Encoder().convert(JsonCodec().encode(data)), 
        publicKey: certificate.key
      );
      if (_verbose) log(TAG, 'send(): end encryption');

      // Send encrypted data
      _aodvManager.sendMessageTo(
        destination, SecureData(ENCRYPTED_DATA, encryptedData).toJson()
      );
    } else {
      // Send unencrypted data
      _aodvManager.sendMessageTo(
        destination, SecureData(UNENCRYPTED_DATA, data).toJson()
      );
    }
  }


  /// Broadcasts a message to all directly connected nodes.
  /// 
  /// The message payload is set to [data] and it is encrypted if [encrypted] is 
  /// set to true.
  /// 
  /// Returns true upon successful broadcast, otherwise false.
  Future<bool> broadcast(Object data, bool encrypted) async {
    if (_verbose) log(TAG, 'broadcast() - encrypted: $encrypted');

    if (encrypted) {
      // Broadcast encrypted data
      for (final neighbor in _datalinkManager.directNeighbors)
        send(data, neighbor.label!, true);
      return true;
    } else {
      // Broadcast unencrypted data
      return await _datalinkManager.broadcastObject(
        SecureData(UNENCRYPTED_DATA, data).toJson()
      );
    }
  }

  /// Broadcasts a message to all directly connected nodes except the excluded
  /// one.
  /// 
  /// The message payload is set to [data] and it is encrypted if [encrypted] is
  /// set to true.
  /// 
  /// The node specified by [excluded] is not included in the broadcast.
  /// 
  /// Returns true upon successful broadcast, otherwise false.
  Future<bool> broadcastExcept(
    Object data, String excluded, bool encrypted
  ) async {
    if (_verbose) log(TAG, 'broadcastExcept() - encrypted: $encrypted');

    if (encrypted) {
      // Encrypt and send encrypted data to direct neighbors except excluded
      for (final neighbor in _datalinkManager.directNeighbors)
        if (neighbor.label != excluded)
          send(data, neighbor.label!, true);
      return true;
    } else {
      // Encrypt and send unencrypted data to direct neighbors except excluded
      return await _datalinkManager.broadcastObjectExcept(
        SecureData(UNENCRYPTED_DATA, data).toJson(), excluded
      );
    }
  }


  /// Revokes this node certificate.
  /// 
  /// Calling this method will send a certificate revocation notification to the
  /// directly trusted neighbors.
  void revokeCertificate() {
    if (_verbose) log(TAG, 'revokeCertificate()');

    // Generate a new pair of public and private key
    AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> newKey = 
      _engine.generateRSAkeyPair();

    _engine.privateKey = newKey.privateKey;
    _engine.publicKey = newKey.publicKey;

    // Unique timestamp to avoid infinite flooding in the network
    String timestamp = 
      _aodvManager.label + DateTime.now().millisecond.toString();
    _setFloodEvents.add(timestamp);

    // Construct a SecureData message for certificate notification
    SecureData msg = SecureData(
      CERT_REVOCATION,
      List.empty(growable: true)
        ..add(timestamp)..add(_aodvManager.label)
        ..add(_engine.publicKey.modulus.toString())
        ..add(_engine.publicKey.exponent.toString())
    );

    // Broadcast certificate revocation notification to direct neighbors
    _datalinkManager.broadcastObject(msg.toJson());
  }

/*------------------------------Private methods-------------------------------*/

  /// Initializes the listening process of lower layer streams.
  void _initialize() {
    _aodvManager.eventStream.listen((event) {
      switch (event.type) {
        case CONNECTION_EVENT:
          // Forward notification to upper layer
          _controller.add(event);

          // Process connection performed with a directly neighbor
          AdHocDevice neighbor = event.payload as AdHocDevice;

          // Generate a message for certificate exchange process
          SecureData msg = SecureData(
            CERT_EXCHANGE,
            [_engine.publicKey.modulus.toString(), 
             _engine.publicKey.exponent.toString()]
          );

          _aodvManager.sendMessageTo(neighbor.label!, msg.toJson());
          break;

        case DATA_RECEIVED:
          // Process data received
          List payload = event.payload as List;
          AdHocDevice sender = payload[0] as AdHocDevice;
          _processData(
            sender, 
            SecureData.fromJson((payload[1] as Map) as Map<String, dynamic>)
          );
          break;

        default:
          // Forward notification to upper layer
          _controller.add(event);
      }
    });

    _groupController.eventStream.listen((event) {
      switch (event.type) {
        case DATA_RECEIVED:
          _controller.add(event);
          break;

        case GROUP_STATUS:
          _controller.add(event);
          break;

        case GROUP_KEY_UPDATED:
          _controller.add(event);
          break;

        default:
      }
    });
  }


  /// Processes certificate reply message.
  /// 
  /// This method performs a certificate chain verification on the list 
  /// [certificateChain].
  /// 
  /// Throws a [VerificationFailedException] upon failure, i.e., a certificate
  /// is not valid.
  void _processCertificateReply(List<Certificate> certificateChain) {
    // Chain verification
    for (final Certificate cert in certificateChain) {
      if (cert.validity.isBefore(DateTime.now()))
        throw VerificationFailedException();
    }

    // Add intermediate nodes' certificates to repository
    for (final Certificate cert in certificateChain)
      _repository.addCertificate(cert);

    // Check if encrypted message needs to be sent to destination node
    Certificate cert = certificateChain.last;
    List<Object>? toSend = _buffer[cert.owner];
    if (toSend == null)
      return;

    // Send encrypted messages
    for (final Object data in toSend)
      send(data, cert.owner, true);
  }


  /// Issues a certificate.
  /// 
  /// Generates a [Certificate] for the binding of the public key [key] and the 
  /// identity of the directly trusted neighbor [label].
  void _issueCertificate(String label, RSAPublicKey key) {
    // Issue the certificate
    DateTime validity = DateTime.now().add(Duration(seconds: _validityPeriod));
    Certificate certificate = 
      Certificate(label, _aodvManager.label, validity, key);

    // Sign the public key
    Uint8List signature = _engine.sign(Utf8Encoder().convert(key.toString()));
    certificate.signature = signature;

    // Add the certificate into the repository
    _repository.addCertificate(certificate);
  }


  /// Processes the data received.
  /// 
  /// The data [pdu] sent by [sender] is processed according to its type.
  void _processData(AdHocDevice sender, SecureData pdu) async {
    String senderLabel = sender.label!;
    switch (pdu.type) {
      case ENCRYPTED_DATA:
        // Decrypt the data received
        Uint8List data = await _engine.decrypt(pdu.payload as List<dynamic>);

        // Notify upper layer of data received
        _controller.add(AdHocEvent(
          DATA_RECEIVED, 
          [sender, JsonCodec().decode(Utf8Decoder().convert(data))])
        );
        break;

      case UNENCRYPTED_DATA:
        // Notify upper layer of data received
        _controller.add(AdHocEvent(DATA_RECEIVED, [sender, pdu.payload]));
        break;

      case CERT_EXCHANGE:
        List<String> _pdu = (pdu.payload as List<dynamic>).cast<String>();
        // Issue a certificate
        _issueCertificate(
          senderLabel,
          RSAPublicKey(BigInt.parse(_pdu.first), BigInt.parse(_pdu.last))
        );
        break;

      case CERT_REQ:
        // Nothing to do
        break;

      case CERT_REP:
        List<Certificate> _pdu = 
          (pdu.payload as List<dynamic>).cast<Certificate>();
        // Process the certificate chain
        try {
          _processCertificateReply(_pdu);
        } catch (exception) {
          _controller.add(AdHocEvent(INTERNAL_EXCEPTION, exception));
        }
        break;

      case CERT_REVOCATION:
        List<String> _pdu = 
          (pdu.payload as List<dynamic>).cast<String>();

        String timestamp = _pdu[0];
        String label = _pdu[1];
        String modulus = _pdu[2];
        String exponent = _pdu[3];

        // Remove the revoked certificate
        _repository.removeCertificate(label);

        // Get list of direct neighbors
        List<AdHocDevice> directNeighbors = _datalinkManager.directNeighbors;

        // Check if the sender is a directly trusted neighbor, if it is, then
        // generate a new certificate
        if (directNeighbors.where((neighbor) => neighbor.label! == label).isNotEmpty) {
          _issueCertificate(
            label,
            RSAPublicKey(BigInt.parse(modulus), BigInt.parse(exponent))
          );
        }

        // Flood control
        if (!_setFloodEvents.contains(timestamp)) {
          // Add the timestamp to the set to avoid rebroadcasting
          _setFloodEvents.add(timestamp);

          // Construct a SecureData message for certificate notification
          SecureData msg = SecureData(CERT_REVOCATION, [timestamp, label]);

          // Broadcast to directly trusted neighbors
          _datalinkManager.broadcastObjectExcept(msg.toJson(), senderLabel);
        }
        break;

      default:
    }
  }
}
