package com.montefiore.thaidinhle.adhoclibrary;

import android.bluetooth.BluetoothManager;
import android.content.Context;
import androidx.annotation.NonNull;

import com.montefiore.thaidinhle.adhoclibrary.bluetoothlowenergy.BluetoothLowEnergyManager;
import com.montefiore.thaidinhle.adhoclibrary.bluetoothlowenergy.GattServerManager;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

public class AdHocPlugin implements FlutterPlugin, MethodCallHandler {
  private static final String CHANNEL_NAME = "ad.hoc.lib/plugin.ble.channel";

  private BluetoothLowEnergyManager bleManager;
  private GattServerManager gattServerManager;
  private MethodChannel methodChannel;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    methodChannel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL_NAME);
    methodChannel.setMethodCallHandler(this);
    
    Context context = binding.getApplicationContext();
    BluetoothManager bluetoothManager = (BluetoothManager) context.getSystemService(Context.BLUETOOTH_SERVICE);

    bleManager = new BluetoothLowEnergyManager();

    gattServerManager = new GattServerManager();
    gattServerManager.openGattServer(bluetoothManager, context);
    gattServerManager.initEventConnectionChannel(binding.getBinaryMessenger());
    gattServerManager.initEventMessageChannel(binding.getBinaryMessenger());
    gattServerManager.initEventMtuChannel(binding.getBinaryMessenger());
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    switch (call.method) {
      case "verbose":
        final boolean verbose = call.arguments();
        bleManager.updateVerboseState(verbose);
        gattServerManager.updateVerboseState(verbose);
        break;

      case "getName":
        final String name = bleManager.getAdapterName();
        result.success(name);
        break;
      case "startAdvertise":
        bleManager.startAdvertise();
        break;
      case "stopAdvertise":
        bleManager.stopAdvertise();
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
    methodChannel.setMethodCallHandler(null);
  }
}
