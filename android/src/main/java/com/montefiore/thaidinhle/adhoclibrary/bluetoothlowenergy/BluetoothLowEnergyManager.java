package com.montefiore.thaidinhle.adhoclibrary.bluetoothlowenergy;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.le.AdvertiseCallback;
import android.bluetooth.le.AdvertiseData;
import android.bluetooth.le.AdvertiseSettings;
import android.bluetooth.le.BluetoothLeAdvertiser;
import android.os.ParcelUuid;
import android.util.Log;

import java.util.UUID;

public class BluetoothLowEnergyManager {
    private static final String TAG = "[AdHocPlugin][BleManager]";

    private final BluetoothAdapter bluetoothAdapter;
    private final BluetoothLeAdvertiser bluetoothLeAdvertiser;

    private boolean verbose;
    private String initialName;

    public BluetoothLowEnergyManager() {
        this.verbose = false;
        this.bluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
        this.bluetoothLeAdvertiser = bluetoothAdapter.getBluetoothLeAdvertiser();
        this.initialName = bluetoothAdapter.getName();
    }

    private AdvertiseCallback advertiseCallback = new AdvertiseCallback() {
        @Override
        public void onStartFailure (int errorCode) {
            if (verbose) Log.d(TAG, "onStartFailure(): " + Integer.toString(errorCode));
            super.onStartFailure(errorCode);
        }

        @Override
        public void onStartSuccess (AdvertiseSettings settingsInEffect) {
            if (verbose) Log.d(TAG, "onStartSuccess()");
            super.onStartSuccess(settingsInEffect);
        }
    };

    public void startAdvertise() {
        if (verbose) Log.d(TAG, "startAdvertise()");

        AdvertiseData data = new AdvertiseData.Builder()
            .addServiceUuid(new ParcelUuid(UUID.fromString(BluetoothLowEnergyUtils.SERVICE_UUID)))
            .setIncludeDeviceName(true)
            .build();

        AdvertiseSettings settings = new AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_BALANCED)
            .setConnectable(true)
            .setTimeout(0) // 0 = no time limit
            .build();

        bluetoothLeAdvertiser.startAdvertising(settings, data, advertiseCallback);
    }

    public void stopAdvertise() {
        if (verbose) Log.d(TAG, "stopAdvertise()");
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

    public void enable() {
        bluetoothAdapter.enable();
    }

    public void disable() {
        bluetoothAdapter.disable();
    }
}
