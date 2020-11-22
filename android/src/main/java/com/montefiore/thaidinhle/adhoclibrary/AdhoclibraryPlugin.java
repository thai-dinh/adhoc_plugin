package com.montefiore.thaidinhle.adhoclibrary;

import androidx.annotation.NonNull;

import com.montefiore.thaidinhle.adhoclibrary.bluetooth.BluetoothAdHocManager;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodChannel;

public class AdhoclibraryPlugin implements FlutterPlugin {
  private static final String CHANNEL = "ad.hoc.lib/blue.manager.channel";
  private static final String STREAM = "ad.hoc.lib/blue.manager.stream";

  private BluetoothAdHocManager bluetoothManager;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    MethodChannel mChannel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL);
    EventChannel eChannel = new EventChannel(binding.getBinaryMessenger(), STREAM);

    bluetoothManager = new BluetoothAdHocManager(true, binding.getApplicationContext(), mChannel, eChannel);
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    bluetoothManager.setMethodCallHandlerToNull();
  }
}
