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

public class AdHocPlugin implements FlutterPlugin, MethodCallHandler {
  private static final String CHANNEL_NAME = "ad.hoc.lib/plugin.ble.channel";

  private BluetoothLowEnergyManager bleManager;
  private GattServerManager gattServerManager;
  private MethodChannel methodChannel;
  private WifiAdHocManager wifiAdHocManager;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    BinaryMessenger messenger = binding.getBinaryMessenger();
    methodChannel = new MethodChannel(messenger, CHANNEL_NAME);
    methodChannel.setMethodCallHandler(this);
    
    Context context = binding.getApplicationContext();
    BluetoothManager bluetoothManager = (BluetoothManager) context.getSystemService(Context.BLUETOOTH_SERVICE);

    bleManager = new BluetoothLowEnergyManager();
    wifiAdHocManager = new WifiAdHocManager(context);

    wifiAdHocManager.initMethodCallHandler(messenger);

    gattServerManager = new GattServerManager();
    gattServerManager.openGattServer(bluetoothManager, context);
    gattServerManager.initEventConnectionChannel(messenger);
    gattServerManager.initEventMessageChannel(messenger);
    gattServerManager.initEventMtuChannel(messenger);
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    switch (call.method) {
      case "verbose":
        final boolean verbose = call.arguments();
        bleManager.updateVerboseState(verbose);
        gattServerManager.updateVerboseState(verbose);
        break;

      case "disable":
        bleManager.disable();
        break;
      case "enable":
        bleManager.enable();
        break;
      case "startAdvertise":
        bleManager.startAdvertise();
        break;
      case "stopAdvertise":
        bleManager.stopAdvertise();
        break;
      case "resetDeviceName":
        result.success(bleManager.resetDeviceName());
        break;
      case "updateDeviceName":
        final String name = call.arguments();
        result.success(bleManager.updateDeviceName(name));
        break;
      case "getAdapterName":
        result.success(bleManager.getAdapterName());
        break;
      case "getPairedDevices":
        result.success(gattServerManager.getConnectedDevices());
        break;

      case "getCurrentName":
        result.success(BluetoothLowEnergyUtils.getCurrentName());
        break;
      case "isEnabled":
        result.success(BluetoothLowEnergyUtils.isEnabled());
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
    wifiAdHocManager.setMethodCallHandler(null);
    methodChannel.setMethodCallHandler(null);
  }
}
