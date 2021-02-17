import 'dart:collection';

import 'package:adhoclibrary/adhoclibrary.dart';


class BlePlugin {
  HashMap<String, AdHocDevice> _discoveredDevices;
  WrapperBluetoothLE _wrapper;

  BlePlugin() {
    Config config = Config();
    config.connectionFlooding = true;
    _wrapper = WrapperBluetoothLE(true, config, HashMap());
  }

/*------------------------------Getters & Setters-----------------------------*/

  List<AdHocDevice> get discoveredDevices {
    List<AdHocDevice> list = List.empty(growable: true);
    _discoveredDevices.entries.forEach((e) => list.add(e.value));
    return list;
  }

/*-------------------------------Public methods-------------------------------*/

  void enableExample() {
    _wrapper.enable(3600, (bool isEnable) => print('BLE: $isEnable'));
  }

  void disableExample() => _wrapper.disable();

  void discoveryExample() {
    _wrapper.discovery((event) {
      if (event.type == Service.DEVICE_DISCOVERED) {
        BleAdHocDevice device = event.payload as BleAdHocDevice;
        print('Device ${device.name} found');
      } else if (event.type == Service.DISCOVERY_END) {
        HashMap<String, AdHocDevice> discoveredDevices = 
          event.payload as HashMap<String, AdHocDevice>;

          _discoveredDevices = discoveredDevices;
      } else {
        print('Example: Discovery started');
      }
    });
  }

  void connectExample(AdHocDevice device) => _wrapper.connect(3, device);

  void stopListeningExample() => _wrapper.stopListening();

  void disconnectAllExample() => _wrapper.disconnectAll();

  void broadcastExample() => _wrapper.broadcast(MessageAdHoc(Header(messageType: 0, label: 'label', name: 'name', deviceType: 1), 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. In molestie orci vel arcu accumsan, vitae tempor leo dapibus. In consequat congue justo sed iaculis. Maecenas mattis enim augue. Integer placerat, lectus nec laoreet commodo, erat erat viverra est, et tincidunt mauris leo in turpis. Donec eros sapien, tempor a metus vel, pharetra sodales velit. Interdum et malesuada fames ac ante ipsum primis in faucibus. Phasellus nulla tellus, tincidunt eu tincidunt ac, interdum in neque. Nunc vitae malesuada arcu. Ut id mattis orci. Proin nec mattis sapien. Morbi hendrerit et lorem eget porta. Donec quis nulla non mauris rutrum suscipit. Curabitur ut porttitor quam. Duis id condimentum nisi. Ut tempus ante sem, sed cursus leo imperdiet quis. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Quisque posuere libero et sodales posuere. Aliquam ligula elit, hendrerit nec egestas at, tempor sed mauris. Suspendisse sit amet maximus ex, vitae posuere dolor. Aliquam cursus, massa ac placerat varius, magna magna ultrices tortor, nec malesuada tellus magna non odio. Praesent sollicitudin diam in ex pretium lobortis. Maecenas facilisis iaculis dui at porttitor. Proin sagittis ligula sed mattis laoreet. Pellentesque lacinia feugiat turpis. Nunc dignissim convallis ullamcorper. In et rhoncus leo. Proin maximus augue in ex lacinia sollicitudin. Nulla facilisi. Etiam finibus felis eu est sollicitudin, in auctor lectus blandit.'));
}
