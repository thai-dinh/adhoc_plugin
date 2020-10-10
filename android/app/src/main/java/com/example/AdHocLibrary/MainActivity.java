package com.example.AdHocLibrary;

import androidx.annotation.NonNull;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "ad.hoc.library.dev/bluetooth";
    private static final String STREAM = "ad.hoc.library.dev/bluetooths.stream";

    private final BluetoothPlugin bluetooth = new BluetoothPlugin(true, getContext());
    
    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
            .setMethodCallHandler(
                (call, result) -> {
                    bluetooth.onMethodCall(call, result);
                }
            );

        EventChannel eventChannel = new EventChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), STREAM);
        bluetooth.setStreamHandler(eventChannel);
    }
}
