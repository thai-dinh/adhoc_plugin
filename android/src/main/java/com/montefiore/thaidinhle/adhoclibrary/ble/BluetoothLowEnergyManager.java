package com.montefiore.thaidinhle.adhoclibrary.ble;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothManager;
import android.bluetooth.le.AdvertiseCallback;
import android.bluetooth.le.AdvertiseData;
import android.bluetooth.le.AdvertiseSettings;
import android.bluetooth.le.BluetoothLeAdvertiser;
import android.content.Context;
import android.os.ParcelUuid;
import android.util.Log;

import com.montefiore.thaidinhle.adhoclibrary.ble.BluetoothUtils;

import java.util.UUID;

public class BluetoothLowEnergyManager {
    private static final String TAG = "[AdHoc.Ble][Ble]";

    private final BluetoothAdapter bluetoothAdapter;
    private final BluetoothLeAdvertiser bluetoothLeAdvertiser;

    public BluetoothLowEnergyManager(BluetoothManager bluetoothManager, Context context) {
        this.bluetoothAdapter = bluetoothManager.getAdapter();
        this.bluetoothLeAdvertiser = bluetoothAdapter.getBluetoothLeAdvertiser();
    }

    public String getAdapterName() {
        return bluetoothAdapter.getName();
    }

    private AdvertiseCallback advertiseCallback = new AdvertiseCallback() {
        @Override
        public void onStartFailure (int errorCode) {
            Log.d(TAG, "startAdvertise() -> onStartFailure(): " + Integer.toString(errorCode));
            super.onStartFailure(errorCode);
        }

        @Override
        public void onStartSuccess (AdvertiseSettings settingsInEffect) {
            Log.d(TAG, "startAdvertise() -> onStartSuccess()");
            super.onStartSuccess(settingsInEffect);
        }
    };

    public void startAdvertise() {
        Log.d(TAG, "startAdvertise()");

        AdvertiseData data = new AdvertiseData.Builder()
            .addServiceUuid(new ParcelUuid(UUID.fromString(BluetoothUtils.SERVICE_UUID)))
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
        Log.d(TAG, "stopAdvertise()");
        bluetoothLeAdvertiser.stopAdvertising(advertiseCallback);
    }
}
