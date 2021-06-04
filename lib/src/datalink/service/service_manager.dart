import 'dart:async';

import 'package:adhoc_plugin/src/datalink/service/adhoc_event.dart';

/// Abstract superclass providing common interfaces for the technology manager
/// 'BleAdHocManager' and 'WifiAdHocManager' classes.
abstract class ServiceManager {
  final bool verbose;

  late bool isDiscovering;
  late StreamController<AdHocEvent> controller;

  /// Creates a [ServiceManager] object.
  ///
  /// The debug/verbose mode is set if [verbose] is true.
  ServiceManager(this.verbose) {
    isDiscovering = false;
    controller = StreamController<AdHocEvent>.broadcast();
  }

/*------------------------------Getters & Setters-----------------------------*/

  /// Ad hoc event stream of the service manager.
  Stream<AdHocEvent> get eventStream => controller.stream;

/*-------------------------------Public methods-------------------------------*/

  /// Closes the stream controller.
  void release() {
    controller.close();
  }

  /// Initializes internal configuration parameters.
  void initialize();

  /// Triggers the discovery process.
  void discovery();

  /// Updates the local adapter name of the device with [newName].
  ///
  /// Returns true if the name is successfully set, otherwise false.
  Future<bool> updateDeviceName(final String newName);

  /// Resets the local adapter name of the device.
  ///
  /// Returns true if the name is successfully reset, otherwise false.
  Future<bool> resetDeviceName();
}
