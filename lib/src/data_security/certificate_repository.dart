import 'dart:collection';

import 'package:adhoc_plugin/src/data_security/certificate.dart';


class CertificateRepository {
  HashMap<String, Certificate> _repository;

  CertificateRepository() {
    this._repository = HashMap();
    this._manageCertificates();
  }

/*------------------------------Public methods--------------------------------*/

  void addCertificate(Certificate certificate) {
    _repository.putIfAbsent(certificate.owner, () => certificate);
  }

  void removeCertificate(String label) {

  }

  Certificate getCertificate(String label) {
    return null;
  }

/*------------------------------Private methods-------------------------------*/

  void _manageCertificates() {

  }
}
