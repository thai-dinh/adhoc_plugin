package com.montefiore.thaidinhle.adhoclibrary.ble;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattDescriptor;
import android.bluetooth.BluetoothGattServer;
import android.bluetooth.BluetoothGattServerCallback;
import android.bluetooth.BluetoothGattService;
import android.bluetooth.le.AdvertiseCallback;
import android.bluetooth.le.AdvertiseData;
import android.bluetooth.le.AdvertiseSettings;
import android.bluetooth.le.BluetoothLeAdvertiser;
import android.content.Context;
import android.util.Log;

import java.util.UUID;

public class BluetoothLowEnergyManager {
    private final String TAG = "[AdHoc.Plugin][BLE.Manager]";
    private final BluetoothAdapter bluetoothAdapter;
    private final BluetoothLeAdvertiser bluetoothLeAdvertiser;

    public BluetoothLowEnergyManager() {
        bluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
        bluetoothLeAdvertiser = bluetoothAdapter.getBluetoothLeAdvertiser();
    }

    private AdvertiseCallback advertiseCallback = new AdvertiseCallback() {
        @Override
        public void onStartFailure (int errorCode) {
            Log.d(TAG, "onStartFailure()");
            super.onStartFailure(errorCode);
        }

        @Override
        public void onStartSuccess (AdvertiseSettings settingsInEffect) {
            Log.d(TAG, "onStartSuccess()");
            super.onStartSuccess(settingsInEffect);
        }
    };

    public void startAdvertise() {
        AdvertiseSettings settings = (new AdvertiseSettings.Builder()).build();
        AdvertiseData data = (new AdvertiseData.Builder()).setIncludeDeviceName(true).build();
        bluetoothLeAdvertiser.startAdvertising(settings, data, advertiseCallback);
    }

    public void stopAdvertise() {
        bluetoothLeAdvertiser.stopAdvertising(advertiseCallback);
    }
}
