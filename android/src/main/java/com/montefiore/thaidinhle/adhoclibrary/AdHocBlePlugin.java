package com.montefiore.thaidinhle.adhoclibrary;

import android.bluetooth.BluetoothManager;
import android.content.Context;
import android.util.Log;
import androidx.annotation.NonNull;

import com.montefiore.thaidinhle.adhoclibrary.ble.BluetoothLowEnergyManager;
import com.montefiore.thaidinhle.adhoclibrary.ble.GattServerManager;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

public class AdHocBlePlugin implements FlutterPlugin, MethodCallHandler {
  private static final String TAG = "[AdHoc.Ble.Plugin][Plugin]";
  private static final String CHANNEL = "ad.hoc.lib/blue.manager.channel";

  private BluetoothLowEnergyManager bleManager;
  private GattServerManager gattServeManager;
  private MethodChannel mChannel;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    Log.d(TAG, "onAttachedToEngine()");

    Context context = binding.getApplicationContext();
    BluetoothManager bluetoothManager =
      (BluetoothManager) context.getSystemService(Context.BLUETOOTH_SERVICE);
    bleManager = new BluetoothLowEnergyManager(bluetoothManager, context);
    gattServeManager = new GattServerManager(bluetoothManager, context);

    mChannel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL);
    mChannel.setMethodCallHandler(this);
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    switch (call.method) {
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

      case "getValue":
        final Byte[] value = gattServeManager.getValue();
        result.success(value);
        break;

      default:
        result.notImplemented();
        break;
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    Log.d(TAG, "onDetachedFromEngine()");
    mChannel.setMethodCallHandler(null);
  }
}
