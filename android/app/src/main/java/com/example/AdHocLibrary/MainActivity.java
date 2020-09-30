package com.example.AdHocLibrary;

import androidx.annotation.NonNull;
import android.bluetooth.BluetoothAdapter;
import android.content.Intent;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "ad.hoc.library.dev/bluetooth";
    private static final BluetoothAdapter btAdapter = 
        BluetoothAdapter.getDefaultAdapter();

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), 
                          CHANNEL)
            .setMethodCallHandler(
                (call, result) -> {
                    switch (call.method) {
                        case "getName":
                            result.success(btAdapter.getName());
                            break;
                        case "enableBtAdapter":
                            btAdapter.enable();
                            break;
                        case "disableBtAdapter":
                            btAdapter.disable();
                            break;
                        case "isBtAdapterEnabled":
                            result.success(btAdapter.isEnabled());
                            break;
                        case "enableBtDiscovery":
                            final int duration = call.argument("duration");
                            result.success(enableBtDiscovery(duration));
                            break;
                        case "updateDeviceName":
                            final String deviceName = call.argument("name");
                            result.success(btAdapter.setName(deviceName));
                            break;
                        case "resetDeviceName":
                            final String name = call.argument("name");
                            btAdapter.setName(name);
                            break;
                        case "isDiscovering":
                            result.success(btAdapter.isDiscovering());
                            break;
                        case "cancelDiscovery":
                            btAdapter.cancelDiscovery();
                            break;
                        default:
                            result.notImplemented();
                    }
                }
            );
    }

    private void enableBtDiscovery(int duration) {
        if (btAdapter != null) {
            Intent discoverableIntent = 
                new Intent(BluetoothAdapter.ACTION_REQUEST_DISCOVERABLE);

            discoverableIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            discoverableIntent.putExtra(
                BluetoothAdapter.EXTRA_DISCOVERABLE_DURATION, duration);

            startActivity(discoverableIntent); // Context relevant for now ?
        }
    }
}
