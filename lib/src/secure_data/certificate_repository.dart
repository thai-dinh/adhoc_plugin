import 'dart:async';
import 'dart:collection';

import 'package:adhoc_plugin/src/appframework/config.dart';
import 'package:adhoc_plugin/src/secure_data/certificate.dart';


/// Class representing the certificate repository. It performs 
/// certificates management, i.e., certificate addition, removal, and periodic
/// validity check.  
class CertificateRepository {
  late HashMap<String, Certificate> _repository;
  late int _period;

  /// Creates a [CertificateRepository] object.
  /// 
  /// This object is configured according to [config], which contains specific 
  /// configurations.
  CertificateRepository(Config config) {
    this._repository = HashMap();
    this._period = config.validityCheck;
    this._checkCertificatesValidity();
  }

/*------------------------------Getters & Setters-----------------------------*/

  /// Returns the list of certificates of this repository.
  List<Certificate> get certificates {
    List<Certificate> certificates = List.empty(growable: true);
    _repository.entries.map((entry) => certificates.add(entry.value));
    return certificates;
  }

/*------------------------------Public methods--------------------------------*/

  /// Adds a [certificate] to the repository
  void addCertificate(Certificate certificate) {
    _repository.update(
      certificate.owner, (value) => certificate, ifAbsent: () => certificate,
    );
  }

  /// Removes the certificate bound to the identity [label] from the repository.
  void removeCertificate(String label) {
    _repository.remove(label);
  }

  /// Gets the certificate bound to the identity [label] from the repository.
  Certificate? getCertificate(String label) {
    return _repository[label];
  }

  /// Checks if the certificate bound to the identity [label] is int the 
  /// repository.
  /// 
  /// Returns true if it is, otherwise, false.
  bool containCertificate(String label) {
    return _repository.containsKey(label);
  }

/*------------------------------Private methods-------------------------------*/

  /// Periodically checks wether a certificate validity has expired or not.
  /// 
  /// If a certificate has expired, then it is simply removed.
  void _checkCertificatesValidity() {
    Timer.periodic(
      Duration(seconds: _period),
      (timer) => _repository.removeWhere(
        (label, certificate) => certificate.validity.isBefore(DateTime.now()),
      )
    );
  }
}
