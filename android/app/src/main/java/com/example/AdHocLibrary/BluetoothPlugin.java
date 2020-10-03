package com.example.AdHocLibrary;

import android.bluetooth.BluetoothAdapter;
import android.content.Context;
import android.content.Intent;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

public class BluetoothPlugin implements MethodCallHandler {
    private final BluetoothAdapter bluetoothAdapter;
    private final String TAG = "[AdHoc][Blue.Manager]";
    private final String initialName;

    private Context context;

    BluetoothPlugin(Context context) {
        this.bluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
        this.initialName = bluetoothAdapter.getName();
        this.context = context;
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        switch (call.method) {
            case "enable":
                bluetoothAdapter.enable();
                break;
            case "disable":
                bluetoothAdapter.disable();
                break;

            case "getName":
                result.success(bluetoothAdapter.getName());
                break;
            case "updateDeviceName":
                final String deviceName = call.argument("name");
                result.success(bluetoothAdapter.setName(deviceName));
                break;
            case "resetDeviceName":
                bluetoothAdapter.setName(initialName);
                break;

            case "enableDiscovery":
                final int duration = call.argument("duration");
                enableDiscovery(duration);
                break;
            case "isDiscovering":
                result.success(bluetoothAdapter.isDiscovering());
                break;
            case "cancelDiscovery":
                bluetoothAdapter.cancelDiscovery();
                break;
            case "startDiscovery":
                discovery();
                break;

            case "getCurrentName":
                result.success(getCurrentName());
                break;
            case "isEnabled":
                result.success(isEnabled());
                break;

            default:
                result.notImplemented();
        }
    }

    private void enableDiscovery(int duration) {
        if (bluetoothAdapter != null) {
            Intent discoverableIntent = 
                new Intent(BluetoothAdapter.ACTION_REQUEST_DISCOVERABLE);

            discoverableIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            discoverableIntent.putExtra(
                BluetoothAdapter.EXTRA_DISCOVERABLE_DURATION, duration);

            context.startActivity(discoverableIntent);
        }
    }

    private void discovery() {
        bluetoothAdapter.startDiscovery();
    }

    private static String getCurrentName() {
        BluetoothAdapter adapter = BluetoothAdapter.getDefaultAdapter();
        if (adapter != null)
            return adapter.getName();
        return null;
    }

    private static boolean isEnabled() {
        return BluetoothAdapter.getDefaultAdapter() != null 
            && BluetoothAdapter.getDefaultAdapter().isEnabled();
    }
}
