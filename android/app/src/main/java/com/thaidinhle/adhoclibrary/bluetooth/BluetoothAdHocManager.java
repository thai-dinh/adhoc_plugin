package com.thaidinhle.adhoclibrary;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.util.Log;

import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.EventChannel.EventSink;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * This class exploits the Bluetooth API of android such as discovery process,
 * retrieving paired devices, and many more. It also defines the StreamHandler
 * of the EventChannel.
 */
public class BluetoothAdHocManager implements MethodCallHandler {
    private static final String TAG = "[AdHoc][Blue.Manager]";

    private final boolean verbose;
    private final BluetoothAdapter bluetoothAdapter;
    private final List<Map<String, Object>> discoveredDevices;
    private final ArrayList<String> devicesFound;
    
    private Context context;
    private EventSink eventSink;
    private String initialName;
    private boolean registeredDiscovery;

    /**
     * Constructor
     *
     * @param verbose   Boolean value to set the debug/verbose mode.
     * @param context   Context object which gives global information about an 
     *                  application environment.
     */
    BluetoothAdHocManager(Boolean verbose, Context context) {
        this.verbose = verbose;
        this.bluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
        this.initialName = bluetoothAdapter.getName();
        this.context = context;
        this.discoveredDevices = new ArrayList<>();
        this.devicesFound = new ArrayList<>();
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
                result.success(bluetoothAdapter.setName(call.argument("name")));
                break;
            case "resetDeviceName":
                if (initialName != null)
                    bluetoothAdapter.setName(initialName);
                break;

            case "enableDiscovery":
                enableDiscovery(call.argument("duration"));
                break;
            case "startDiscovery":
                discovery();
                break;

            case "getPairedDevices":
                result.success(getPairedDevices());
                break;
            case "unpairDevice":
                try { 
                    unpairDevice(call.argument("address"));
                } catch(Exception e) {
                    Log.d(TAG, e.getMessage());
                }
                break;

            default:
                result.notImplemented();
        }
    }

    /**
     * Method allowing to set the StreamHandler of an EventChannel.
     * 
     * @param eventChannel  Named channel for communicating with the Flutter 
     *                      application using asynchronous event streams.
     */
    public void setStreamHandler(EventChannel eventChannel) {
        eventChannel.setStreamHandler(
            new EventChannel.StreamHandler() {
                @Override
                public void onListen(Object arguments, EventSink events) {
                    eventSink = events;
                }

                @Override
                public void onCancel(Object arguments) {
                    unregisterReceiver();
                }
            }
        );
    }

    /**
     * Method allowing to set the device into a discovery mode.
     *
     * @param duration  Integer value between 0 and 3600 which represents the 
     *                  time of the discovery mode.
     */
    private void enableDiscovery(int duration) {
        if (bluetoothAdapter != null) {
            Intent intent = new Intent(BluetoothAdapter.ACTION_REQUEST_DISCOVERABLE);

            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            intent.putExtra(BluetoothAdapter.EXTRA_DISCOVERABLE_DURATION, duration);

            context.startActivity(intent);
        }
    }

    /**
     * Method allowing to discover other bluetooth devices.
     */
    private void discovery() {
        if (verbose) Log.d(TAG, "discovery()");

        if (bluetoothAdapter.isDiscovering()) {
            Log.d(TAG, "cancelDiscovery");
            bluetoothAdapter.cancelDiscovery();
        }

        IntentFilter filter = new IntentFilter();

        filter.addAction(BluetoothDevice.ACTION_FOUND);
        filter.addAction(BluetoothAdapter.ACTION_DISCOVERY_STARTED);
        filter.addAction(BluetoothAdapter.ACTION_DISCOVERY_FINISHED);

        context.registerReceiver(receiver, filter);
        registeredDiscovery = true;

        bluetoothAdapter.startDiscovery();
    }

    /**
     * Method allowing to unregister the discovery broadcast.
     */
    private void unregisterReceiver() {
        if (registeredDiscovery) {
            if (verbose) Log.d(TAG, "unregisterDiscovery()");
            context.unregisterReceiver(receiver);
            registeredDiscovery = false;
        }
    }

    /**
     * Base class for code that receives and handles broadcast intents sent by
     * {@link android.content.Context#sendBroadcast(Intent)}.
     */
    private final BroadcastReceiver receiver = new BroadcastReceiver() {
        public void onReceive(Context context, Intent intent) {
            String action = intent.getAction();

            if (BluetoothDevice.ACTION_FOUND.equals(action)) {
                BluetoothDevice device = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE);

                int rssi = intent.getShortExtra(BluetoothDevice.EXTRA_RSSI, Short.MIN_VALUE);
                String deviceName = device.getName();
                String deviceHardwareAddress = device.getAddress();

                if (!devicesFound.contains(deviceHardwareAddress)) {
                    if (verbose) Log.d(TAG, deviceName + " " + deviceHardwareAddress);

                    devicesFound.add(deviceHardwareAddress);

                    Map<String, Object> btDevice = new HashMap<>();
                    btDevice.put("deviceName", deviceName);
                    btDevice.put("macAddress", deviceHardwareAddress);
                    btDevice.put("rssi", rssi);

                    discoveredDevices.add(btDevice);

                    eventSink.success(btDevice);
                }
            } else if (BluetoothAdapter.ACTION_DISCOVERY_STARTED.equals(action)) {
                if (verbose) Log.d(TAG, "ACTION_DISCOVERY_STARTED");

                discoveredDevices.clear();
                devicesFound.clear();
            } else if (BluetoothAdapter.ACTION_DISCOVERY_FINISHED.equals(action)) {
                if (verbose) Log.d(TAG, "ACTION_DISCOVERY_FINISHED");

                eventSink.success(discoveredDevices);
                eventSink.endOfStream();
            }
        }
    };

    /**
     * Method allowing to get all the paired Bluetooth devices.
     *
     * @return a List<Map<String, Object>> that contains HashMap, which maps the
     *         a device's name to its value and the device's address to its
     *         mac address. 
     */
    private List<Map<String, Object>> getPairedDevices() {
        if (verbose) Log.d(TAG, "getPairedDevicesInfo()");

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

    /**
     * Method allowing to unpair a previously paired bluetooth device.
     *
     * @param macAddress    String representing the MAC address of a device.
     * @throws InvocationTargetException signals that a method does not exist.
     * @throws IllegalAccessException    signals that an application tries to reflectively create
     *                                   an instance which has no access to the definition of
     *                                   the specified class
     * @throws NoSuchMethodException     signals that a method does not exist.
     */
    private void unpairDevice(String macAddress) 
        throws InvocationTargetException, IllegalAccessException, NoSuchMethodException {
        if (verbose) Log.d(TAG, "unpairDevice()");

        BluetoothDevice device = bluetoothAdapter.getRemoteDevice(macAddress);
        Method method = device.getClass().getMethod("removeBond", (Class[]) null);
        method.invoke(device, (Object[]) null);
    }
}
