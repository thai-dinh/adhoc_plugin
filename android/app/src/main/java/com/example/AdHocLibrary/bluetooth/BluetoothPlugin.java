package com.example.AdHocLibrary;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.util.Log;

import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

public class BluetoothPlugin implements MethodCallHandler {
    private static final String TAG = "[AdHoc][Blue.Manager]";

    private final BluetoothAdapter bluetoothAdapter;
    private final List<Map<String, Object>> discoveredDevices;
    private final ArrayList<String> devicesFound;
    
    private Context context;
    private String initialName;
    private boolean registeredDiscovery;

    private EventChannel.EventSink event;

    BluetoothPlugin(Context context) {
        this.bluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
        this.initialName = bluetoothAdapter.getName();
        this.context = context;
        this.discoveredDevices = new ArrayList<>();
        this.devicesFound = new ArrayList<>();
        this.registeredDiscovery = false;
    }

    public void test(EventChannel eventChannel) {
        eventChannel.setStreamHandler(
            new EventChannel.StreamHandler() {
                @Override
                public void onListen(Object arguments, EventChannel.EventSink events) {
                    event = events;
                }

                @Override
                public void onCancel(Object arguments) {

                }
            } 
        );
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
            case "startDiscovery":
                discovery();
                break;

            case "getPairedDevices":
                result.success(getPairedDevices());
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
        Log.d(TAG, "discovery()");

        cancelDiscovery();

        IntentFilter filter = new IntentFilter();

        filter.addAction(BluetoothDevice.ACTION_FOUND);
        filter.addAction(BluetoothAdapter.ACTION_DISCOVERY_STARTED);
        filter.addAction(BluetoothAdapter.ACTION_DISCOVERY_FINISHED);

        context.registerReceiver(receiver, filter);

        bluetoothAdapter.startDiscovery();
    }

    private final BroadcastReceiver receiver = new BroadcastReceiver() {
        public void onReceive(Context context, Intent intent) {
            String action = intent.getAction();

            if (BluetoothDevice.ACTION_FOUND.equals(action)) {
                BluetoothDevice device = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE);

                int rssi = intent.getShortExtra(BluetoothDevice.EXTRA_RSSI, Short.MIN_VALUE);
                String deviceName = device.getName();
                String deviceHardwareAddress = device.getAddress();

                if (!devicesFound.contains(deviceHardwareAddress)) {
                    Log.d(TAG, deviceName + " " + deviceHardwareAddress);

                    devicesFound.add(deviceHardwareAddress);

                    Map<String, Object> btDevice = new HashMap<>();
                    btDevice.put("deviceName", deviceName);
                    btDevice.put("macAddress", deviceHardwareAddress);
                    btDevice.put("rssi", rssi);

                    discoveredDevices.add(btDevice);

                    event.success(btDevice);
                }
            } else if (BluetoothAdapter.ACTION_DISCOVERY_STARTED.equals(action)) {
                Log.d(TAG, "ACTION_DISCOVERY_STARTED");

                discoveredDevices.clear();
                devicesFound.clear();
            } else if (BluetoothAdapter.ACTION_DISCOVERY_FINISHED.equals(action)) {
                Log.d(TAG, "ACTION_DISCOVERY_FINISHED");

                event.success(discoveredDevices);
                event.endOfStream();
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

    private List<Map<String, Object>> getPairedDevices() {
        Log.d(TAG, "getPairedDevicesInfo()");

        Set<BluetoothDevice> bondedDevices = bluetoothAdapter.getBondedDevices();
        List<Map<String, Object>> pairedDevices = new ArrayList<>();

        if (bondedDevices.size() > 0) {
            for (BluetoothDevice device : bondedDevices) {
                Log.d(TAG, "Name: " + device.getName() + " - MAC: " + device.getAddress());

                Map<String, Object> bondedDevice = new HashMap<>();
                bondedDevice.put("deviceName", device.getName());
                bondedDevice.put("macAddress", device.getAddress());

                pairedDevices.add(bondedDevice);
            }
        }

        return pairedDevices;
    }
}
