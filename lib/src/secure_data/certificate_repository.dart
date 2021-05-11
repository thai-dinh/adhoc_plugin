import 'dart:collection';

import 'package:adhoc_plugin/src/secure_data/certificate.dart';



class CertificateRepository {
  late HashMap<String?, Certificate> _repository;

  CertificateRepository() {
    this._repository = HashMap();
    this._manageCertificates();
  }

/*------------------------------Getters & Setters-----------------------------*/

  List<Certificate> get certificates {
    List<Certificate> certificates = List.empty(growable: true);
    _repository.entries.map((entry) => certificates.add(entry.value));
    return certificates;
  }

/*------------------------------Public methods--------------------------------*/

  void addCertificate(Certificate certificate) {
    _repository.putIfAbsent(certificate.owner, () => certificate);
  }

  void removeCertificate(String label) {
    _repository.remove(label);
  }

  Certificate? getCertificate(String? label) {
    return _repository[label];
  }

  bool containCertificate(String label) {
    return _repository.containsKey(label);
  }

/*------------------------------Private methods-------------------------------*/

  void _manageCertificates() {
    // Periodically check wether a certificate validity has expired or not
  }
}
