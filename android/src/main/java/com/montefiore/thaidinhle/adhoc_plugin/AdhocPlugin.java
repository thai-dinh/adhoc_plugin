package com.montefiore.thaidinhle.adhoc_plugin;

import android.bluetooth.BluetoothManager;
import android.content.Context;
import androidx.annotation.NonNull;

import com.montefiore.thaidinhle.adhoc_plugin.ble.BleManager;
import com.montefiore.thaidinhle.adhoc_plugin.ble.BleUtils;
import com.montefiore.thaidinhle.adhoc_plugin.ble.GattServerManager;
import com.montefiore.thaidinhle.adhoc_plugin.wifi.WifiAdHocManager;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/**
 * Class managing the Android platform-specific code, which is responsible 
 * of managing platform call from the Flutter client.
 */
public class AdhocPlugin implements FlutterPlugin, MethodCallHandler {
  private static final String METHOD_NAME = "ad.hoc.lib/ble.method.channel";

  private MethodChannel methodChannel;
  private BinaryMessenger messenger;
  private Context context;

  private BleManager bleManager;
  private BluetoothManager bluetoothManager;
  private GattServerManager gattServerManager;

  private WifiAdHocManager WifiAdHocManager;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    this.messenger = binding.getBinaryMessenger();
    this.context = binding.getApplicationContext();
    this.bluetoothManager = 
      (BluetoothManager) context.getSystemService(Context.BLUETOOTH_SERVICE);

    // Attach this plugin to the Flutter environment
    methodChannel = new MethodChannel(messenger, METHOD_NAME);
    methodChannel.setMethodCallHandler(this);

    // GattServerManager and BleManager (BLE)
    gattServerManager = new GattServerManager(context);
    bleManager = new BleManager();

    // WifiAdHocManager (Wi-Fi Direct)
    WifiAdHocManager = new WifiAdHocManager(context);
    WifiAdHocManager.initMethodCallHandler(messenger);
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    // Method that communicate with the Flutter client (Platform Channel)
    switch (call.method) {
      case "setVerbose":
        final boolean verbose = call.arguments();
        bleManager.setVerbose(verbose);
        gattServerManager.setVerbose(verbose);
        break;
      case "isEnabled":
        result.success(BleUtils.isEnabled());
        break;
      case "openGattServer":
        gattServerManager.openGattServer(bluetoothManager, context);
        gattServerManager.setupEventChannel(messenger);
        break;
      case "closeGattServer":
        gattServerManager.closeGattServer();
        break;
      case "cancelConnection":
        final String macAddress = call.arguments();
        gattServerManager.cancelConnection(macAddress);
      case "getCurrentName":
        result.success(BleUtils.getCurrentName());
        break;

      case "disable":
        result.success(bleManager.disable());
        break;
      case "enable":
        result.success(bleManager.enable());
        break;
      case "startAdvertise":
        bleManager.startAdvertise();
        break;
      case "stopAdvertise":
        bleManager.stopAdvertise();
        break;
      case "updateDeviceName":
        final String name = call.arguments();
        result.success(bleManager.updateDeviceName(name));
        break;
      case "resetDeviceName":
        result.success(bleManager.resetDeviceName());
        break;
      case "getAdapterName":
        result.success(bleManager.getAdapterName());
        break;
      case "getPairedDevices":
        result.success(gattServerManager.getConnectedDevices());
        break;
      case "getBondState":
        final String address = call.arguments();
        result.success(gattServerManager.getBondState(address));
        break;
      case "createBond":
        final String remoteAddress = call.arguments();
        result.success(gattServerManager.createBond(remoteAddress));
        break;

      default:
        result.notImplemented();
        break;
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    bleManager.stopAdvertise();
    gattServerManager.closeGattServer();
    WifiAdHocManager.close();
    methodChannel.setMethodCallHandler(null);
  }
}
