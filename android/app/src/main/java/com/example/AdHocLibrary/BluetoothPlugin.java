package com.example.AdHocLibrary;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.util.Log;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

import java.util.ArrayList;

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
            case "isEnabled":
                result.success(bluetoothAdapter.isEnabled());
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

            case "getBondedDevices":
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
        Log.d(TAG, "DISCOVERY");

        IntentFilter filter = new IntentFilter();

        filter.addAction(BluetoothDevice.ACTION_FOUND);
        filter.addAction(BluetoothAdapter.ACTION_DISCOVERY_STARTED);
        filter.addAction(BluetoothAdapter.ACTION_DISCOVERY_FINISHED);

        context.registerReceiver(mReceiver, filter);

        bluetoothAdapter.startDiscovery();
    }

    private final BroadcastReceiver mReceiver = new BroadcastReceiver() {
        public void onReceive(Context context, Intent intent) {
            String action = intent.getAction();
            Log.d(TAG, "onReceive");
            if (BluetoothDevice.ACTION_FOUND.equals(action)) {
                Log.d(TAG, "DEVICE_FOUND");
            } else if (BluetoothAdapter.ACTION_DISCOVERY_STARTED.equals(action)) {
                Log.d(TAG, "ACTION_DISCOVERY_STARTED");
            } else if (BluetoothAdapter.ACTION_DISCOVERY_FINISHED.equals(action)) {
                Log.d(TAG, "ACTION_DISCOVERY_FINISHED");
            }
        }
    };
}
