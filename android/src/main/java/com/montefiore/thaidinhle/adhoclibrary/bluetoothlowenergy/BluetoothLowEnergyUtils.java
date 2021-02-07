package com.montefiore.thaidinhle.adhoclibrary.bluetoothlowenergy;

import android.bluetooth.BluetoothAdapter;

public class BluetoothLowEnergyUtils {
    public static final String SERVICE_UUID = "00000001-0000-1000-8000-00805f9b34fb";
    public static final String CHARACTERISTIC_UUID = "00000002-0000-1000-8000-00805f9b34fb";
    public static final String IDENTIFIER_UUID = "00000003-0000-1000-8000-00805f9b34fb";

    public static final int IDENTIFIER = 0;
    public static final int CONNECTION_STATUS = 1;

    public static final int END_MESSAGE = 0;

    public static final int STATE_DISCONNECTED = 0;
    public static final int STATE_CONNECTED = 1;

    public static String getCurrentName() {
        BluetoothAdapter mBluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
        return (mBluetoothAdapter != null) ? mBluetoothAdapter.getName() : null;
    }

    public static boolean isEnabled() {
        return BluetoothAdapter.getDefaultAdapter() != null && BluetoothAdapter.getDefaultAdapter().isEnabled();
    }
}