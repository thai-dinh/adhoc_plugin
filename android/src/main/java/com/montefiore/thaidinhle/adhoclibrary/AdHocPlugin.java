package com.montefiore.thaidinhle.adhoclibrary;

import android.bluetooth.BluetoothManager;
import android.content.Context;
import androidx.annotation.NonNull;

import com.montefiore.thaidinhle.adhoclibrary.ble.BluetoothLowEnergyManager;
import com.montefiore.thaidinhle.adhoclibrary.ble.GattServerManager;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

public class AdHocPlugin implements FlutterPlugin, MethodCallHandler {
  private static final String CHANNEL_NAME = "ad.hoc.lib/plugin.ble.channel";
  private static final String STREAM_NAME = "ad.hoc.lib/plugin.ble.stream";

  private BluetoothLowEnergyManager bleManager;
  private GattServerManager gattServerManager;
  private MethodChannel methodChannel;
  private EventChannel eventChannel;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    Context context = binding.getApplicationContext();
    BluetoothManager bluetoothManager =
      (BluetoothManager) context.getSystemService(Context.BLUETOOTH_SERVICE);

    bleManager = new BluetoothLowEnergyManager(bluetoothManager, context);

    gattServerManager = new GattServerManager(bluetoothManager, context);
    gattServerManager.setupGattServer();

    methodChannel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL_NAME);
    methodChannel.setMethodCallHandler(this);

    eventChannel = new EventChannel(binding.getBinaryMessenger(), STREAM_NAME);
    eventChannel.setStreamHandler(gattServerManager.initStreamHandler());
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

      default:
        result.notImplemented();
        break;
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    gattServerManager.closeGattServer();
    methodChannel.setMethodCallHandler(null);
    eventChannel.setStreamHandler(null);
  }
}
