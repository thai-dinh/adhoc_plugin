package com.montefiore.thaidinhle.adhoc_plugin.ble;

import android.bluetooth.BluetoothAdapter;

/**
 * Miscellaneous class for Bluetooth Low Energy.
 */
public class BleUtils {
    // Gatt service and characteristic UUID
    public static final String SERVICE_UUID = "00000001-0000-1000-8000-00805f9b34fb";
    public static final String CHARACTERISTIC_UUID = "00000002-0000-1000-8000-00805f9b34fb";
    // Minimum Bluetooth Low Energy mtu
    public static final byte MIN_MTU = 20;
    // TAG for data fragmentation
    public static final byte MESSAGE_END = 0;
    public static final byte MESSAGE_FRAG = 1;
    // TAG for connection state with a remote peer
    public static final byte STATE_DISCONNECTED = 0;
    public static final byte STATE_CONNECTED = 1;

    /**
     * Static method allowing to get the current name of the Bluetooth adapter.
     * 
     * @return String value representing the adapter name.
     */
    public static String getCurrentName() {
        BluetoothAdapter mBluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
        return (mBluetoothAdapter != null) ? mBluetoothAdapter.getName() : null;
    }

    /**
     * Static method allowing to check whether the Bluetooth adapter is enabled
     * 
     * @return true if it is, otherwise false.
     */
    public static boolean isEnabled() {
        return BluetoothAdapter.getDefaultAdapter() != null && BluetoothAdapter.getDefaultAdapter().isEnabled();
    }
}