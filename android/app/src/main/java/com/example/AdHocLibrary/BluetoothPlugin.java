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

import java.util.HashMap;

public class BluetoothPlugin implements MethodCallHandler {
    private final BluetoothAdapter bluetoothAdapter;
    private final String TAG = "[AdHoc][Blue.Manager]";
    private final HashMap<String, BluetoothDevice> btDevices;
    
    private Context context;
    private String initialName;
    private boolean registeredDiscovery;

    BluetoothPlugin(Context context) {
        this.bluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
        this.initialName = bluetoothAdapter.getName();
        this.context = context;
        this.btDevices = new HashMap<>();
        this.registeredDiscovery = false;
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
                cancelDiscovery();
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

    private void cancelDiscovery() {
        if (bluetoothAdapter.isDiscovering()) {
            Log.d(TAG, "cancelDiscovery()");
            bluetoothAdapter.cancelDiscovery();
        }

        unregisterDiscovery();
    }

    private void discovery() {
        Log.d(TAG, "DISCOVERY");

        IntentFilter filter = new IntentFilter();

        filter.addAction(BluetoothDevice.ACTION_FOUND);
        filter.addAction(BluetoothAdapter.ACTION_DISCOVERY_STARTED);
        filter.addAction(BluetoothAdapter.ACTION_DISCOVERY_FINISHED);

        filter.addAction(BluetoothAdapter.ACTION_STATE_CHANGED);

        context.registerReceiver(receiver, filter);

        boolean val = bluetoothAdapter.startDiscovery();
        Log.d(TAG, Boolean.toString(val));
        Log.d(TAG, Boolean.toString(bluetoothAdapter.isDiscovering()));
    }

    private final BroadcastReceiver receiver = new BroadcastReceiver() {
        public void onReceive(Context context, Intent intent) {
            String action = intent.getAction();

            if (BluetoothDevice.ACTION_FOUND.equals(action)) {
                BluetoothDevice device = 
                    intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE);

                String deviceName = device.getName();
                String deviceHardwareAddress = device.getAddress();

                if (!btDevices.containsKey(deviceHardwareAddress)) {
                    Log.d(TAG, deviceName + " " + deviceHardwareAddress);
                    btDevices.put(deviceHardwareAddress, device);
                }
            } else if (BluetoothAdapter.ACTION_DISCOVERY_STARTED.equals(action)) {
                Log.d(TAG, "ACTION_DISCOVERY_STARTED");

                btDevices.clear();
            } else if (BluetoothAdapter.ACTION_DISCOVERY_FINISHED.equals(action)) {
                Log.d(TAG, "ACTION_DISCOVERY_FINISHED");
            }
        }
    };

    private void unregisterDiscovery() {
        if (registeredDiscovery) {
            Log.d(TAG, "unregisterDiscovery()");
            context.unregisterReceiver(receiver);
            registeredDiscovery = false;
        }
    }

    private void unpairDevice(BluetoothDevice device) {
        Log.d(TAG, "unpairDevice()");

        // %TODO: to finish
    }

    private HashMap<String, BluetoothDevice> getPairedDevices() {
        Log.d(TAG, "getPairedDevices()");

        Set<BluetoothDevice> pairedDevices = bluetoothAdapter.getBondedDevices();
        HashMap<String, BluetoothDevice> hashMapPairedDevices = new HashMap<>();

        if (pairedDevices.size() > 0) {
            for (BluetoothDevice device : pairedDevices) {
                Log.d(TAG, "Name: " + device.getName() + " - MAC: " + device.getAddress());

                hashMapPairedDevices.put(device.getAddress(), device);
            }
        }

        return hashMapPairedDevices;
    }
}
