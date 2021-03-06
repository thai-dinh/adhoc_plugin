package com.montefiore.thaidinhle.adhoclibrary;

import android.bluetooth.BluetoothManager;
import android.content.Context;
import androidx.annotation.NonNull;

import com.montefiore.thaidinhle.adhoclibrary.bluetoothlowenergy.BluetoothLowEnergyManager;
import com.montefiore.thaidinhle.adhoclibrary.bluetoothlowenergy.BluetoothLowEnergyUtils;
import com.montefiore.thaidinhle.adhoclibrary.bluetoothlowenergy.GattServerManager;
import com.montefiore.thaidinhle.adhoclibrary.wifi.WifiAdHocManager;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

import java.io.IOException;


public class AdHocPlugin implements FlutterPlugin, MethodCallHandler {
  private static final String CHANNEL_NAME = "ad.hoc.lib/plugin.ble.channel";

  private BinaryMessenger messenger;
  private BluetoothLowEnergyManager bleManager;
  private BluetoothManager bluetoothManager;
  private Context context;
  private GattServerManager gattServerManager;
  private MethodChannel methodChannel;
  private WifiAdHocManager wifiAdHocManager;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    this.messenger = binding.getBinaryMessenger();
    this.context = binding.getApplicationContext();
    this.bluetoothManager = 
      (BluetoothManager) context.getSystemService(Context.BLUETOOTH_SERVICE);

    methodChannel = new MethodChannel(messenger, CHANNEL_NAME);
    methodChannel.setMethodCallHandler(this);

    gattServerManager = new GattServerManager();
    bleManager = new BluetoothLowEnergyManager();
    wifiAdHocManager = new WifiAdHocManager(context);
    wifiAdHocManager.initMethodCallHandler(messenger);
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    switch (call.method) {
      case "setVerbose":
        final boolean verbose = call.arguments();
        bleManager.setVerbose(verbose);
        gattServerManager.setVerbose(verbose);
        break;
      case "isEnabled":
        result.success(BluetoothLowEnergyUtils.isEnabled());
        break;
      case "openGattServer":
        gattServerManager.openGattServer(bluetoothManager, context);
        gattServerManager.initEventChannels(messenger);
        break;
      case "closeGattServer":
        gattServerManager.closeGattServer();
        break;
      case "sendMessage":
        try {
          final String mac = call.argument("mac");
          final String message = call.argument("message");
          result.success(gattServerManager.writeToCharacteristic(message, mac)); 
        } catch (IOException exception) {
          result.success(false);
        }
        break;
      case "cancelConnection":
        final String macAddress = call.arguments();
        gattServerManager.cancelConnection(macAddress);
      case "getCurrentName":
        result.success(BluetoothLowEnergyUtils.getCurrentName());
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

      default:
        result.notImplemented();
        break;
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    bleManager.stopAdvertise();
    gattServerManager.closeGattServer();
    wifiAdHocManager.close();
    methodChannel.setMethodCallHandler(null);
  }
}
