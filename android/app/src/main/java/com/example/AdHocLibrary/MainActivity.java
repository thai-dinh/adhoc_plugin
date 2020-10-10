package com.example.AdHocLibrary;

import androidx.annotation.NonNull;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "ad.hoc.library.dev/bluetooth.channel";
    private static final String STREAM = "ad.hoc.library.dev/bluetooth.stream";

    private final BluetoothAdHocManager bluetooth = 
        new BluetoothAdHocManager(true, getContext());
    
    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        EventChannel eventChannel = 
            new EventChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), STREAM);
        bluetooth.setStreamHandler(eventChannel);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
            .setMethodCallHandler(
                (call, result) -> {
                    bluetooth.onMethodCall(call, result);
                }
            );
    }
}
