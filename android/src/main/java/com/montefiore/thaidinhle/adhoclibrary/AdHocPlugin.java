package com.montefiore.thaidinhle.adhoclibrary;

import android.bluetooth.BluetoothManager;
import android.content.Context;
import androidx.annotation.NonNull;

import com.montefiore.thaidinhle.adhoclibrary.ble.BluetoothLowEnergyManager;
import com.montefiore.thaidinhle.adhoclibrary.ble.GattServerManager;
import com.montefiore.thaidinhle.adhoclibrary.wifi.WifiAdHocManager;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

import java.util.HashMap;

public class AdHocPlugin implements FlutterPlugin, MethodCallHandler {
  private static final String BLECHANNEL = "ad.hoc.lib/plugin.ble.channel";
  private static final String WIFICHANNEL = "ad.hoc.lib/plugin.wifi.channel";

  private BluetoothLowEnergyManager bleManager;
  private GattServerManager gattServerManager;
  private MethodChannel bChannel;
  private MethodChannel wChannel;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    Context context = binding.getApplicationContext();
    BluetoothManager bluetoothManager =
      (BluetoothManager) context.getSystemService(Context.BLUETOOTH_SERVICE);
    bleManager = new BluetoothLowEnergyManager(bluetoothManager, context);

    gattServerManager = new GattServerManager(bluetoothManager, context);
    gattServerManager.setupGattServer();

    bChannel = new MethodChannel(binding.getBinaryMessenger(), BLECHANNEL);
    bChannel.setMethodCallHandler(this);

    wChannel = new MethodChannel(binding.getBinaryMessenger(), WIFICHANNEL);
    wChannel.setMethodCallHandler(new WifiAdHocManager(binding.getBinaryMessenger(), context));
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
      case "getValues":
        final HashMap<String, byte[]> values = gattServerManager.getValues();
        result.success(values);
        break;

      default:
        result.notImplemented();
        break;
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    bChannel.setMethodCallHandler(null);
    wChannel.setMethodCallHandler(null);
  }
}
