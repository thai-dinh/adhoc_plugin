package com.montefiore.thaidinhle.adhoc_plugin.ble;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.le.AdvertiseCallback;
import android.bluetooth.le.AdvertiseData;
import android.bluetooth.le.AdvertiseSettings;
import android.bluetooth.le.BluetoothLeAdvertiser;
import android.os.ParcelUuid;
import android.util.Log;

import java.util.UUID;

public class BleManager {
    private static final String TAG = "[AdHocPlugin][BleManager]";

    private final BluetoothAdapter bluetoothAdapter;

    private BluetoothLeAdvertiser bluetoothLeAdvertiser;
    private boolean verbose;
    private String initialName;

    public BleManager() {
        this.verbose = false;
        this.bluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
        this.bluetoothLeAdvertiser = bluetoothAdapter.getBluetoothLeAdvertiser();
        this.initialName = bluetoothAdapter.getName();
    }

    private AdvertiseCallback advertiseCallback = new AdvertiseCallback() {
        @Override
        public void onStartFailure (int errorCode) {
            if (verbose) 
                Log.d(TAG, "Start advertise failure: " + Integer.toString(errorCode));
            super.onStartFailure(errorCode);
        }

        @Override
        public void onStartSuccess (AdvertiseSettings settingsInEffect) {
            if (verbose) 
                Log.d(TAG, "Start advertise success");
            super.onStartSuccess(settingsInEffect);
        }
    };

    public void startAdvertise() {
        if (verbose) Log.d(TAG, "startAdvertise()");

        AdvertiseData data = new AdvertiseData.Builder()
            .addServiceUuid(new ParcelUuid(UUID.fromString(BleUtils.SERVICE_UUID)))
            .setIncludeDeviceName(true)
            .build();

        AdvertiseSettings settings = new AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_BALANCED)
            .setConnectable(true)
            .setTimeout(0) // 0 = no time limit
            .build();

        if (bluetoothLeAdvertiser == null) {
            bluetoothLeAdvertiser = bluetoothAdapter.getBluetoothLeAdvertiser();
            if (bluetoothLeAdvertiser == null)
                return;
        }
    
        bluetoothLeAdvertiser.startAdvertising(settings, data, advertiseCallback);
    }

    public void stopAdvertise() {
        if (verbose) Log.d(TAG, "stopAdvertise()");

        if (bluetoothLeAdvertiser != null)
            bluetoothLeAdvertiser.stopAdvertising(advertiseCallback);
    }

    public void setVerbose(boolean verbose) {
        this.verbose = verbose;
    }

    public boolean resetDeviceName() {
        if (initialName != null)
            return bluetoothAdapter.setName(initialName);
        return false;
    }

    public boolean updateDeviceName(String name) {
        return bluetoothAdapter.setName(name);
    }

    public String getAdapterName() {
        return bluetoothAdapter.getName();
    }

    public boolean enable() {
        return bluetoothAdapter.enable();
    }

    public boolean disable() {
        return bluetoothAdapter.disable();
    }
}
