package com.montefiore.thaidinhle.adhoclibrary;

import android.util.Log;
import androidx.annotation.NonNull;

import com.montefiore.thaidinhle.adhoclibrary.bluetooth.BluetoothAdHocManager;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.EventChannel.EventSink;
import io.flutter.plugin.common.EventChannel.StreamHandler;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

public class AdhoclibraryPlugin implements FlutterPlugin, MethodCallHandler, StreamHandler {
  private static final String CHANNEL = "ad.hoc.lib/blue.manager.channel";
  private static final String STREAM = "ad.hoc.lib/blue.manager.stream";

  private BluetoothAdHocManager bluetoothManager;
  private EventChannel eChannel;
  private MethodChannel mChannel;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    Log.d("TAG", "onAttachedToEngine");

    bluetoothManager = new BluetoothAdHocManager(true, binding.getApplicationContext());

    eChannel = new EventChannel(binding.getBinaryMessenger(), STREAM);
    mChannel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL);

    eChannel.setStreamHandler(this);
    mChannel.setMethodCallHandler(this);
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    eChannel.setStreamHandler(null);
    mChannel.setMethodCallHandler(null);
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    bluetoothManager.onMethodCall(call, result);
  }

  @Override
  public void onListen(Object arguments, EventSink events) {
    bluetoothManager.onListen(events);
  }

  @Override
  public void onCancel(Object arguments) {
    bluetoothManager.onCancel();
  }
}
