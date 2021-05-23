package com.montefiore.thaidinhle.adhoc_plugin.ble;

import android.bluetooth.BluetoothAdapter;

public class BleUtils {
    public static final String SERVICE_UUID = "00000001-0000-1000-8000-00805f9b34fb";
    public static final String CHARACTERISTIC_UUID = "00000002-0000-1000-8000-00805f9b34fb";

    public static final byte MIN_MTU = 20;

    public static final byte MESSAGE_END = 0;
    public static final byte MESSAGE_FRAG = 1;

    public static final byte STATE_DISCONNECTED = 0;
    public static final byte STATE_CONNECTED = 1;

    public static String getCurrentName() {
        BluetoothAdapter mBluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
        return (mBluetoothAdapter != null) ? mBluetoothAdapter.getName() : null;
    }

    public static boolean isEnabled() {
        return BluetoothAdapter.getDefaultAdapter() != null && BluetoothAdapter.getDefaultAdapter().isEnabled();
    }
}