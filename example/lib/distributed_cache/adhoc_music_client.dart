import 'package:adhoclibrary/adhoclibrary.dart';


class AdHocMusicClient {
  TransferManager _manager;

  AdHocMusicClient() {
    this._manager = TransferManager(true);
    this._initializer();
  }

/*-------------------------------Public methods-------------------------------*/

  void searchDevices() => _manager.startDiscovery();

/*------------------------------Private methods-------------------------------*/

  void _initializer() {
    this._manager.eventStream.listen((event) {

    });
  }
}
