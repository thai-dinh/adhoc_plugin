import 'dart:async';
import 'dart:collection';

import 'package:adhoc_plugin/src/appframework/config.dart';
import 'package:adhoc_plugin/src/secure_data/certificate.dart';


class CertificateRepository {
  late HashMap<String, Certificate> _repository;
  late int _period;

  CertificateRepository(Config config) {
    this._repository = HashMap();
    this._period = config.validityPeriod;
    this._checkCertificatesValidity();
  }

/*------------------------------Getters & Setters-----------------------------*/

  List<Certificate> get certificates {
    List<Certificate> certificates = List.empty(growable: true);
    _repository.entries.map((entry) => certificates.add(entry.value));
    return certificates;
  }

/*------------------------------Public methods--------------------------------*/

  void addCertificate(Certificate certificate) {
    _repository.update(
      certificate.owner, (value) => certificate, ifAbsent: () => certificate,
    );
  }

  void removeCertificate(String label) {
    _repository.remove(label);
  }

  Certificate? getCertificate(String label) {
    return _repository[label];
  }

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
        (label, certificate) => certificate.validity.isBefore(DateTime.now()
      ),
    ));
  }
}
