import 'package:adhoc_plugin/src/data_security/certificate_repository.dart';
import 'package:adhoc_plugin/src/data_security/crypto_engine.dart';

class CryptoManager {
  CertificateRepository _repository;
  CryptoEngine _engine;

  CryptoManager() {
    this._repository = CertificateRepository();
    this._engine = CryptoEngine();
  }

/*------------------------------Getters & Setters-----------------------------*/

/*------------------------------Public methods--------------------------------*/

/*------------------------------Private methods-------------------------------*/

}
