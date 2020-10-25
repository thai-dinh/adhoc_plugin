package com.thaidinhle.adhoclibrary;

import androidx.annotation.NonNull;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String WIFI = "ad.hoc.library.dev/wifi";
    private final WifiAdHocManager wifiManager = new WifiAdHocManager(true, getContext());

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        MethodChannel wifiChannel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), WIFI);
        wifiChannel.setMethodCallHandler(
            (call, result) -> {
                wifiManager.onMethodCall(call, result);
            }
        );

        new BluetoothAdHocManager(true, getContext(), flutterEngine);
        new BluetoothSocketManager(flutterEngine);
    }
}
