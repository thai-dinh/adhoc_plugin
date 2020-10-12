package com.example.AdHocLibrary;

import androidx.annotation.NonNull;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodChannel;

import android.content.Context;
import android.net.wifi.WifiManager;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;


public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "ad.hoc.library.dev/bluetooth.channel";
    private static final String STREAM = "ad.hoc.library.dev/bluetooth.stream";
    private static final String WIFI = "ad.hoc.library.dev/wifi";

    private final BluetoothAdHocManager bluetooth = new BluetoothAdHocManager(true, getContext());
    private final WifiAdHocManager wifiManager = new WifiAdHocManager(getContext());

    private MethodChannel wifiChannel;

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

        wifiChannel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), WIFI);
        wifiChannel.setMethodCallHandler(
            (call, result) -> {
                wifiManager.onMethodCall(call, result);
            }
        );
    }
}

class WifiAdHocManager implements MethodCallHandler {
    private static final String TAG = "[AdHoc][WifiManager]";

    private Context context;

    WifiAdHocManager(Context context) {
        this.context = context;
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        switch (call.method) {
            case "enable":
                wifiAdapterState(true);
                break;
            case "disable":
                disable();
                break;
            default:
                break;
        }
    }

    private void wifiAdapterState(boolean state) {
        WifiManager wifi = (WifiManager) context.getApplicationContext().getSystemService(Context.WIFI_SERVICE);
        if (wifi != null) {
            wifi.setWifiEnabled(state);
        }
    }

    private void disable() {
        wifiAdapterState(false);
    }
}
